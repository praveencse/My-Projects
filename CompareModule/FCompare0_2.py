
import sys
import getopt
import os
import stat
import itertools
from itertools import filterfalse
import webbrowser


_cache = {}
BUFFER = 8*1024

IGNORE_LIST = ['.coo','.map','.o','.git']

class HtmlUtility:
    
    def __init__(self, report_html, report=None): # Initialize
        self.html = open(report_html,'w')
        self.report = report
        message = """<html>
        <head></head>
        <body><p>Hello World!</p></body>
        </html>"""
        self.html.write(message)
        
    def writeTo(self,message):
        self.html.write(message)
    
    def openWebbrowser(self):    
        webbrowser.open_new_tab(report_html)
    
    def __del__(self):
        message="""</html>"""
        self.html.write(message)
        self.html.close()




def clear_cache():
    """Clear the filecompare cache."""
    _cache.clear()

def _sig(st):
    return (stat.S_IFMT(st.st_mode),
            st.st_size,
            st.st_mtime)

def doCompare(f1, f2):
    bufsize = BUFFER
    with open(f1, 'rb') as fp1, open(f2, 'rb') as fp2:
        while True:
            b1 = fp1.read(bufsize)
            b2 = fp2.read(bufsize)
            if b1 != b2:
                return False
            if not b1:
                return True

# Compare Utility Class
#
class CompareUtility:
    """
    High level usage:
      x = CompareUtility(dir1, dir2)
      x.report() -> prints a report on the differences between dir1 and dir2
       or
     x.report_full_closure() -> like report_partial_closure,
            but fully recursive.
    Attributes:
     left_list, right_list: The files in dir1 and dir2,
        filtered by hide and ignore.
     common: a list of names in both dir1 and dir2.
     left_only, right_only: names only in dir1, dir2.
     common_dirs: subdirectories in both dir1 and dir2.
     common_files: files in both dir1 and dir2.
     common_funny: names in both dir1 and dir2 where the type differs between
        dir1 and dir2, or the name is not stat-able.
     same_files: list of identical files.
     diff_files: list of filenames which differ.
     funny_files: list of files which could not be compared.
     subdirs: a dictionary of CompareUtility objects, keyed by names in common_dirs.
     """

    def __init__(self, a, b, ignore=None, hide=None): # Initialize
        self.left = a
        self.right = b
        if hide is None:
            self.hide = [os.curdir, os.pardir] # Names never to be shown
        else:
            self.hide = hide
        if ignore is None:
            self.ignore = IGNORE_LIST
        else:
            self.ignore = ignore

    def phase0(self): # Compare everything except common subdirectories
        self.left_list = _filter(os.listdir(self.left),
                                 self.hide+self.ignore)
        self.right_list = _filter(os.listdir(self.right),
                                  self.hide+self.ignore)
        self.left_list.sort()
        self.right_list.sort()

    def phase1(self): # Compute common names
        a = dict(zip(map(os.path.normcase, self.left_list), self.left_list))
        b = dict(zip(map(os.path.normcase, self.right_list), self.right_list))
        self.common = list(map(a.__getitem__, filter(b.__contains__, a)))
        self.left_only = list(map(a.__getitem__, filterfalse(b.__contains__, a)))
        self.right_only = list(map(b.__getitem__, filterfalse(a.__contains__, b)))

    def phase2(self): # Distinguish files, directories, funnies
        self.common_dirs = []
        self.common_files = []
        self.common_funny = []

        for x in self.common:
            a_path = os.path.join(self.left, x)
            b_path = os.path.join(self.right, x)

            ok = 1
            try:
                a_stat = os.stat(a_path)
            except OSError as why:
                # print('Can\'t stat', a_path, ':', why.args[1])
                ok = 0
            try:
                b_stat = os.stat(b_path)
            except OSError as why:
                # print('Can\'t stat', b_path, ':', why.args[1])
                ok = 0

            if ok:
                a_type = stat.S_IFMT(a_stat.st_mode)
                b_type = stat.S_IFMT(b_stat.st_mode)
                if a_type != b_type:
                    self.common_funny.append(x)
                elif stat.S_ISDIR(a_type):
                    self.common_dirs.append(x)
                elif stat.S_ISREG(a_type):
                    self.common_files.append(x)
                else:
                    self.common_funny.append(x)
            else:
                self.common_funny.append(x)

    def phase3(self): # Find out differences between common files
        xx = compareFiles(self.left, self.right, self.common_files)
        self.same_files, self.diff_files, self.funny_files = xx

    def phase4(self): # Find out differences between common subdirectories
        # A new CompareUtility object is created for each common subdirectory,
        # these are stored in a dictionary indexed by filename.
        # The hide and ignore properties are inherited from the parent
        self.subdirs = {}
        for x in self.common_dirs:
            a_x = os.path.join(self.left, x)
            b_x = os.path.join(self.right, x)
            self.subdirs[x]  = CompareUtility(a_x, b_x, self.ignore, self.hide)

    def phase4_closure(self): # Recursively call phase4() on subdirectories
        self.phase4()
        for sd in self.subdirs.values():
            sd.phase4_closure()

    def report(self): # Print a report on the differences between a and b
        # Output format is purposely lousy
     #   print('diff', self.left, self.right)
        if self.left_only:
            self.left_only.sort()
    #        print('Only in', self.left, ':', self.left_only)
        if self.right_only:
            self.right_only.sort()
    #        print('Only in', self.right, ':', self.right_only)
        if self.same_files:
            self.same_files.sort()
    #        print('Identical files :', self.same_files)
        if self.diff_files:
            self.diff_files.sort()
            print('diff', self.left, self.right)
            print('Differing files :', self.diff_files)
            ff.writeTo(self.left);
            ff.writeTo(self.right);
        if self.funny_files:
            self.funny_files.sort()
    #        print('Trouble with common files :', self.funny_files)
        if self.common_dirs:
            self.common_dirs.sort()
    #        print('Common subdirectories :', self.common_dirs)
        if self.common_funny:
            self.common_funny.sort()
    #        print('Common funny cases :', self.common_funny)

   
    def report_full_closure(self): # Report on self and subdirs recursively
        self.report()
        for sd in self.subdirs.values():
            print()
            sd.report_full_closure()

    methodmap = dict(subdirs=phase4,
                     same_files=phase3, diff_files=phase3, funny_files=phase3,
                     common_dirs = phase2, common_files=phase2, common_funny=phase2,
                     common=phase1, left_only=phase1, right_only=phase1,
                     left_list=phase0, right_list=phase0)

    def __getattr__(self, attr):
        if attr not in self.methodmap:
            raise AttributeError(attr)
        self.methodmap[attr](self)
        return getattr(self, attr)

def compareFiles(a, b, common, shallow=True):
    """Compare common files in two directories.
    a, b -- directory names
    common -- list of file names found in both directories
    shallow -- if true, do comparison based solely on stat() information
    Returns a tuple of three lists:
      files that compare equal
      files that are different
      filenames that aren't regular files.
    """
    res = ([], [], [])
    for x in common:
        ax = os.path.join(a, x)
        bx = os.path.join(b, x)
        res[_compare(ax, bx, shallow)].append(x)
    return res

def compare(f1, f2, shallow=True):
    """Compare two files.
    Arguments:
    f1 -- First file name
    f2 -- Second file name
    shallow -- Just check stat signature (do not read the files).
               defaults to True.
    Return value:
    True if the files are the same, False otherwise.
    This function uses a cache for past comparisons and the results,
    with cache entries invalidated if their stat information
    changes.  The cache may be cleared by calling clear_cache().
    """

    s1 = _sig(os.stat(f1))
    s2 = _sig(os.stat(f2))
    if s1[0] != stat.S_IFREG or s2[0] != stat.S_IFREG:
        return False
    if shallow and s1 == s2:
        return True
    if s1[1] != s2[1]:
        return False

    outcome = _cache.get((f1, f2, s1, s2))
    if outcome is None:
        outcome = doCompare(f1, f2)
        if len(_cache) > 100:      # limit the maximum size of the cache
            clear_cache()
        _cache[f1, f2, s1, s2] = outcome
    return outcome

# Compare two files.
# Return:
#       0 for equal  1 for different  2 Exception
#
def _compare(a, b, sh, abs=abs, compare=compare):
    try:
        return not abs(compare(a, b, sh))
    except OSError:
        return 2


# Return a copy with items that occur in skip removed.
#
def _filter(flist, skip):
    return list(filterfalse(skip.__contains__, flist))


# CompareUtility Usage
#
def startCompare():
    global ff
    ff = HtmlUtility('report.html')
     
    options, args = getopt.getopt(sys.argv[1:], 'r')
   # args = getopt.getopt(sys.argv[1:])
    if len(args) != 2:
        raise getopt.GetoptError('need exactly two args', None)
    dd = CompareUtility(args[0],args[1])
    print("Report")
#   dd.report()
    print("Report Full Closure")
    dd.report_full_closure()
    

        
if __name__ == '__main__':
    startCompare()
    