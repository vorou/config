# bigfiles.py: Support versions of big files with storage outside hg repo. 
#
# Copyright 2008 Andrei Vermel <andrei.vermel@gmail.com>
#
# This software may be used and distributed according to the terms
# of the GNU General Public License, incorporated herein by reference.

'''support versions of big files with storage outside hg repo. 
To setup the extension add to a config file:
[bigfiles]
repo = path/to/versions/dir 

Big files are not put to hg repo. They are listed in a file called 
'.bigfiles', which also serves as an ignore file similar to .hgignore, so they
do not clutter output of hg commands. The file also stores check sums of the 
big files in a form of comments. File '.bigfiles' is versioned by hg, so each
changeset knows which big files it uses from the names and checksums.
The file can be diffed and merged, which is nice.

The versions of big files are stored in a versions directory, with checksums
attached to filenames.
The extension overrides 'hg update', so that it can compare contents of 
'.bigfiles' before and after the update to remove and fetch appropriate big 
files.
The directory storing versions of big files can be synced with the remote one 
(the extension doesn't do this, but tells the list of the necessary files).
The versions corresponding to old changesets can be removed to save space.

To add a new big file, use normal 'hg add', ignoring the size warning.
To remove a tracked big file, just delete it.
Then use:
'hg bstatus' - to examine state of big files in working directory.
'hg brefresh' - to refresh '.bigfiles' and versions directory with added, 
    removed and modified big files.
'hg bupdate' - to fetch files from versions directory as recorded in 
    '.bigfiles', and get a list of necessary files missing in the
    version directory.'''

from mercurial.i18n import _
from mercurial.node import *
from mercurial import commands, hg, node, util, extensions, scmutil
import os, stat, cPickle, errno, re
import hashlib
import gzip
_sha1 = hashlib.sha1

def write_dotbigfilesfile(repo, bigfiles):
    fp = open(repo.wjoin('.bigfiles'), 'w')
    fp.write("syntax: glob\n\n")
    for f in sorted(bigfiles.keys()):
        fp.write("%s#%s\n" % (f, bigfiles[f]))
    fp.close()

def parse_bigfiles(repo):
    fname = repo.wjoin('.bigfiles')
    bigfiles = {}
    try:
        for str in open(fname):
            if '#' not in str:
                continue
            path, hash = str.strip().rsplit('#', 1)
            bigfiles[path] = hash
    except IOError, err:
        if err.errno != errno.ENOENT: raise
    return bigfiles 

def bigfiles_repo(ui):
    brepo = ui.config('bigfiles', 'repo')
    if not brepo:
        raise util.Abort(_('bigfiles.repo path not configured'))
    try:
        st=os.lstat(brepo)
        if not stat.S_ISDIR(st.st_mode):
            raise util.Abort(
               _('specified bigfiles repo %s is not a directory') % brepo)
    except OSError:        
        raise util.Abort(_("can't access bigfiles repo: %s") % brepo)
    return brepo

def _hash(f):
    #print("getting hash of %s" % f)
    file = open(f, 'rb')
    s = _sha1("")
    while True: 
        text = file.read(1000000)
        if text=='':
            break
        s.update(text)
    return s.hexdigest()

def read_bigfiledirstate(ui, repo):
    ds = {}
    try:
        fp = open(repo.wjoin(".hg/bigfiledirstate"), "rb")
        ds = cPickle.load(fp)
        fp.close()
    except IOError, err:
        if err.errno != errno.ENOENT: raise
    return ds

def write_bigfiledirstate(ui, repo, ds):
    fp = open(repo.wjoin(".hg/bigfiledirstate"), "wb")
    cPickle.dump(ds, fp)
    fp.close()

def update_bigfiledirstate(repo, file, st, ds):
    ds[file] = (st.st_size, st.st_mtime, _hash(repo.wjoin(file)))

def accelerated_hash(repo, file, st, ds):
    if file in ds:
        t = ds[file]
        if t[0] == st.st_size and t[1] == st.st_mtime:
            return t[2]
    update_bigfiledirstate(repo, file, st, ds)
    return ds[file][2]

def _bigstatus(ui, repo, pats, opts, ds, bigfiles):
    MAX_SIZE = 10000000
    brepo = bigfiles_repo(ui)

    tracked_gotbig = [] # not in .bigfiles
    added_big = []      # not in .bigfiles
    modified = []       # already in .bigfiles
    removed = []        # missing, but still in .bigfiles
    gotsmall = []       # still in .bigfiles
    missinginrepo = []  # file recorded in .bigfiles not in bigfiles repo

    node1, node2 = scmutil.revpair(repo, None)
    mod_all, added_all = repo.status(node1, node2, 
        scmutil.match(repo[None], pats, opts), None, None, True)[0:2]

    for file in mod_all:
        f=repo.wjoin(file)
        fsize=os.lstat(f).st_size
        if fsize > MAX_SIZE:
            tracked_gotbig.append(file)

    for file in added_all:
        f=repo.wjoin(file)
        fsize=os.lstat(f).st_size
        if fsize > MAX_SIZE:
            added_big.append(file)

    for file, hash in bigfiles.iteritems():
        f=repo.wjoin(file)
        try:
            st = os.lstat(f)
        except OSError:
            frepo = "%s/%s.%s" % (brepo, file, hash)
            if os.path.exists(frepo) or os.path.exists(frepo+'.gz'):
                removed.append(file)
            else:
                missinginrepo.append(file)
            continue
        if st.st_size <= MAX_SIZE:
            gotsmall.append(file)
        fhash = accelerated_hash(repo, file, st, ds)
        if fhash != hash:
            modified.append(file)

    return tracked_gotbig, added_big, modified, removed, gotsmall, \
        missinginrepo

def bigstatus(ui, repo, *pats, **opts):
    '''show changed big files in the working directory
    Show status of big files in the repository.

    The codes used to show the status of files are:
    B = tracked by hg, got too big. 
    A = added to hg, too big
    M = modified
    S = got small, can now be tracked by hg
    ! = missing in working dir, present in versions repo
    R = missing in both working dir and versions repo'''

    ds = read_bigfiledirstate(ui, repo)
    bigfiles = parse_bigfiles(repo)
    bst = _bigstatus(ui, repo, pats, opts, ds, bigfiles)
    codes = ('B', 'A', 'M', '!', 'S', 'R')
    for files, code in zip(bst, codes):
       for f in files:
         if opts['no_status']:
             ui.write("%s\n" % f)
         else:
             ui.write("%s %s\n" % (code, f))
    write_bigfiledirstate(ui, repo, ds)

def _updatebigrepo(ui, repo, files, brepo, bigfiles, ds):
    for file in files:
        f = repo.wjoin(file)
        hash = accelerated_hash(repo, file, os.lstat(f), ds)
        bigfiles[file] = hash
        rf = "%s/%s.%s" % (brepo, file, hash)
        util.makedirs(os.path.dirname(rf))
        try:
            ext = f.split('.')[-1]
            dont_pack=['gz', 'zip', 'tgz', '7z', 'jpg', 'jpeg', 'gif', 
                'mpg', 'mpeg', 'avi', 'rar', 'cab']
            if ext in dont_pack:
                util.copyfile(f, rf)
            else:
                fo = open(f, 'rb')
                rfo_fileobj = open(rf+'.gz', 'wb')
                rfo = gzip.GzipFile(file+'.'+hash, 'wb', 9, rfo_fileobj)
                def read10Mb():
                    return fo.read(1024*1024*10)
                for chunk in iter(read10Mb, ''):
                    rfo.write(chunk)
                fo.close()
                rfo.close()
                rfo_fileobj.close()
        except:
            ui.write(_('failed to store %s\n') % f)

def bigrefresh(ui, repo, *pats, **opts):
    '''update big files tracking as per working directory. 

    Added big files get forgotten and added to '.bigfiles' instead.
    Removed big files are deleted from '.bigfiles'. 
    Files tracked by hg that got too big are removed from hg, and added 
    to '.bigfiles'. 
    Copies of new and modified big files are stored in versions directory.'''
 
    ds = read_bigfiledirstate(ui, repo)
    bigfiles = parse_bigfiles(repo)
    tracked_gotbig, added_big, modified, removed, gotsmall, \
        missinginrepo = _bigstatus(ui, repo, pats, opts, ds, bigfiles)
    for f in added_big:
        ui.write(_("forgetting %s\n") % f) 
    if not opts['dry_run']:
        repo[None].forget(added_big)

    for f in tracked_gotbig:
        ui.write(_("removing %s\n") % f) 
    if not opts['dry_run']:
        repo[None].forget(tracked_gotbig)

    for f in removed+missinginrepo:
        ui.write(_("recording removal of %s\n") % f) 

    brepo = bigfiles_repo(ui)

    if not opts['dry_run']:
        _updatebigrepo(ui, repo, tracked_gotbig + added_big + modified,
           brepo, bigfiles, ds)
        for file in removed+missinginrepo:
            del bigfiles[file]

        write_dotbigfilesfile(repo, bigfiles)
    write_bigfiledirstate(ui, repo, ds)

def badd(ui, repo, *pats, **opts):
    """add the specified files to big files repo
    If no names are given, add all files to the repository.
    """
    setignores(ui)
    ds = read_bigfiledirstate(ui, repo)
    bigfiles = parse_bigfiles(repo)

    bad = []
    exacts = {}
    names = []
    m = scmutil.match(repo[None], pats, opts)
    oldbad = m.bad
    m.bad = lambda x,y: bad.append(x) or oldbad(x,y)

    for f in repo.walk(m):
        exact = m.exact(f)
        if exact or f not in repo.dirstate:
            names.append(f)
            if ui.verbose or not exact:
                ui.status(_('adding %s\n') % m.rel(f))

    if not opts.get('dry_run'):
        brepo = bigfiles_repo(ui)
        _updatebigrepo(ui, repo, names, brepo, bigfiles, ds)
        write_dotbigfilesfile(repo, bigfiles)
        write_bigfiledirstate(ui, repo, ds)

    return bad and 1 or 0


def bigupdate(ui, repo, *pats, **opts):
    '''fetch files from versions directory as recorded in '.bigfiles'. 
 
    Also complain about necessary files missing in the version directory'''
    ds = read_bigfiledirstate(ui, repo)
    bigfiles = parse_bigfiles(repo)
    tracked_gotbig, added_big, modified, removed, gotsmall, \
        missinginrepo = _bigstatus(ui, repo, pats, opts, ds, bigfiles)
    brepo = bigfiles_repo(ui)

    tocopy = removed
    if opts['clean']:
      tocopy = tocopy+modified
    for file in tocopy:
        f = repo.wjoin(file)
        hash= bigfiles[file]
        rf = "%s/%s.%s" % (brepo, file, hash)
        ui.write(_("fetching %s\n") % rf) 
        if not opts['dry_run']:
            util.makedirs(os.path.dirname(f))
            if os.path.exists(f):
                util.unlink(f)
            if os.path.exists(rf):
               util.copyfile(rf, f)
            else:
               fo = open(f, 'wb')
               rfo = gzip.open(rf + '.gz', 'rb')
               def read10Mb():
                   return rfo.read(1024*1024*10)
               for chunk in iter(read10Mb, ''):
                   fo.write(chunk)
               fo.close()
               rfo.close()
    if missinginrepo:
        ui.write(_("\nNeeded files missing in bigrepo %s:\n") % brepo) 
        for file in missinginrepo:
            hash = bigfiles[file]
            ui.write("%s.%s\n" % (file, hash)) 
    write_bigfiledirstate(ui, repo, ds)

def my_update(orig, ui, repo, *args, **opts):
    bigfiles0 = parse_bigfiles(repo)
    res = orig(ui, repo, *args, **opts)
    if opts.get('clean'):
        return res
    bigfiles1 = parse_bigfiles(repo)

    m1 = None
    m2 = None
    for file in bigfiles0.keys():
        if file not in bigfiles1:
            if not m1:
                parent1, parent2 = repo.dirstate.parents()
                m1 = repo[parent1].manifest()
                m2 = repo[parent2].manifest()
            if file in m1 or file not in m2:
                continue
            try:
                f = repo.wjoin(file)
                os.lstat(f)
                ui.write(_("unlinking %s.%s\n") % (file, bigfiles0[file])) 
                util.unlink(f)
            except OSError:
                pass

    tofetch = {}
    for file, hash in bigfiles1.iteritems():
        if file not in bigfiles0 or bigfiles0[file] != hash:
            tofetch[file] = hash
    for file in bigfiles0:
        if file not in bigfiles1 and file not in repo.dirstate and \
           os.path.exists(file):
           ui.write(_("unlinking %s.%s\n") % (file, bigfiles0[file])) 
           util.unlink(file)

    if tofetch:
        brepo = bigfiles_repo(ui)
        missing = {}
        for file, hash in tofetch.iteritems():
            f = repo.wjoin(file)
            rf = "%s/%s.%s" % (brepo, file, hash)

            util.makedirs(os.path.dirname(f))
            if os.path.exists(f):
                util.unlink(f)
            if os.path.exists(rf):
                util.copyfile(rf, f)
            else:
                rf = rf + '.gz'
                if os.path.exists(rf):
                    ui.write(_("fetching %s.%s\n") % (file, hash)) 
                    fo = open(f, 'wb')
                    rfo = gzip.open(rf, 'rb')
                    def read10Mb():
                        return rfo.read(1024*1024*10)
                    for chunk in iter(read10Mb, ''):
                        fo.write(chunk)
                    fo.close()
                    rfo.close()
                else:
                    missing[file] = hash
        if missing:
            ui.write(_("\nNeeded files missing in bigrepo %s:\n") % brepo) 
            for file, hash in missing.iteritems():
                ui.write("%s.%s\n" % (file, hash)) 
    return res

def _findrepo(p):
    while not os.path.isdir(os.path.join(p, ".hg")):
        oldp, p = p, os.path.dirname(p)
        if p == oldp:
            return None

    return p

def setignores(ui):
    path_bigfiles = _findrepo(os.getcwd())
    if path_bigfiles == None:
        return
    path_bigfiles = path_bigfiles+'/.bigfiles'
    try:
        os.stat(path_bigfiles)
    except:
        return
    ui.setconfig("ui", "ignore.bigfiles", path_bigfiles)

def wraptosetignores(orig, ui, *args, **opts):
    setignores(ui)
    res = orig(ui, *args, **opts)
    return res

def uisetup(ui):
    extensions.wrapcommand(commands.table, 'update', my_update)
    
    for cmd_names in commands.table.keys(): # wrap everything to add ignores to ui. yuk!
        aliases = cmd_names.lstrip("^").split("|")
        extensions.wrapcommand(commands.table, aliases[0], wraptosetignores)

dryrunopts = [('n', 'dry-run', None,
               _('do not perform actions, just print output'))]

walkopts = [
    ('I', 'include', [], _('include names matching the given patterns')),
    ('X', 'exclude', [], _('exclude names matching the given patterns')),
]

cmdtable = {
    "bigadd|badd": (badd, walkopts + dryrunopts, _('[OPTION]... [FILE]...')),
    'bigstatus|bstatus':
        (bigstatus,
         [('n', 'no-status', None, _('hide status prefix')),
         ] + commands.walkopts,
        _('hg bigstatus [SOURCE]')),
    'bigrefresh|brefresh':
        (bigrefresh,
         [('n', 'dry-run', None, _('do not perform actions, just print output')),
         ] + commands.walkopts,
        _('hg bigrefresh [SOURCE]')),
    'bigupdate|bup|bigcheckout|bco':
        (bigupdate,
         [('n', 'dry-run', None, _('do not perform actions, just print output')),
          ('C', 'clean', None, _('overwrite modified files')),
         ] + commands.walkopts,
        _('hg bigupdate [SOURCE]')),
}

