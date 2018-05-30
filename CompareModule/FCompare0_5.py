
import sys
import getopt
import os
import stat
import itertools
from itertools import filterfalse
import webbrowser
import difflib
import re
_cache = {}

IGNORE_LIST = ['*.coo','*.*.map','*.map','*.xml','*.o','*.d','.git']

class HtmlUtils:
    
    def __init__(self, report_html, report=None): # Initialize
        self.difftxt = open("difftxt.txt",'w')
        self.report_html = report_html
        self.html = open(report_html,'w')
        self.report = report
        message = """<html>
        <font face="Times New Roman" size="+1" color="Black">
        <h1>
        <head>FMPP File Comparison</head>
        </h1>
        <body><p>"""
        self.html.write(message)
        
    def writeTo(self,message):
               
                self.html.write('<table border="4" cellpadding="2"')
                self.html.write('cellspacing="2" width="100%">')
                self.html.write('<tr>')
                self.html.write('<td>')
                self.html.write('<font face="Times New Roman" size="+1" color="Blue">')
                self.html.write('<h3>')
                self.html.write(message)
                self.html.write('</h3>')
                self.html.write('</font>')
                self.html.write('</td>')
                self.html.write('</tr>')
                self.html.write('</table>')
                
        
    def writeDiff(self,message):
#                self.html.write('<table border="4" cellpadding="2"')
#                self.html.write('cellspacing="2" width="100%">')
#                self.html.write('<tr>')
#                self.html.write('<td>')
                for line in message.splitlines():
                    if re.match('^[-+@]+', line):
                            self.html.write('<font face="Times New Roman" size="+1" color="Red">')
                            self.html.write('<h4>')
                            self.html.write(line)
                            self.html.write('<h4>')
                            
 #               self.html.write('</td>')
 #               self.html.write('</tr>')
 #               self.html.write('</table>')
                     
    def  openWebbrowser(self):    
        webbrowser.open_new_tab(self.report_html)
    
    def __del__(self):
        self.html.write('</p></body>')
        message="""</html>"""
        self.html.write(message)
        self.html.close()
        self.difftxt.close()

def clear_cache():
    """Clear the filecompare cache."""
    _cache.clear()

"""
The stat module defines constants and functions for interpreting the results of os.stat(), os.fstat() and os.lstat() 
(if they exist). For complete details about the stat(), fstat() and lstat() calls, 
consult the documentation for your system.
"""
def _sig(st):
    return (stat.S_IFMT(st.st_mode),
            st.st_size,
            st.st_mtime)

def doCompare(f1, f2):
    bufsize = 8*1024
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
class CompareUtils:
    """
    High level usage:
      x = CompareUtils(dir1, dir2)
      x.report() -> prints a report on the differences between dir1 and dir2
       or
     x.generateDiffReport() ->fully recursive.
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

    def step02_FindAll(self): # Compare everything except common subdirectories
        self.left_list = _filter(os.listdir(self.left),
                                 self.hide+self.ignore)
        self.right_list = _filter(os.listdir(self.right),
                                  self.hide+self.ignore)
        self.left_list.sort()
        self.right_list.sort()

    def step01_FindCommonName(self): # Compute common names
        a = dict(zip(map(os.path.normcase, self.left_list), self.left_list))
        b = dict(zip(map(os.path.normcase, self.right_list), self.right_list))
        self.common = list(map(a.__getitem__, filter(b.__contains__, a)))
        self.left_only = list(map(a.__getitem__, filterfalse(b.__contains__, a)))
        self.right_only = list(map(b.__getitem__, filterfalse(a.__contains__, b)))

    def step02_Difffiles_CommonFiles(self): # Distinguish files, directories, funnies
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

    def step03_FindDiffCommonFiles(self): # Find out differences between common files
        xx = compareFiles(self.left, self.right, self.common_files)
        self.same_files, self.diff_files, self.funny_files = xx

    def step04_FindDiffCommonFilesInSubDirectories(self): # Find out differences between common subdirectories
        # A new CompareUtils object is created for each common subdirectory,
        # these are stored in a dictionary indexed by filename.
        # The hide and ignore properties are inherited from the parent
        self.subdirs = {}
        for x in self.common_dirs:
            a_x = os.path.join(self.left, x)
            b_x = os.path.join(self.right, x)
            self.subdirs[x]  = CompareUtils(a_x, b_x, self.ignore, self.hide)

    def step04_FindDiffCommonFilesInSubDirectories_closure(self): # Recursively calling step04_FindDiffCommonFilesInSubDirectories() on subdirectories
        self.step04_FindDiffCommonFilesInSubDirectories()
        for sd in self.subdirs.values():
            sd.step04_FindDiffCommonFilesInSubDirectories_closure()

    def report(self): # Print a report on the differences between a and b
        if self.diff_files:
            self.diff_files.sort()
            print('diff', self.left, self.right)
            print('Differing files :', self.diff_files)
#            ff.writeTo('\n')
#            ff.writeTo(self.left)
#            ff.writeTo('\n')
#            ff.writeTo(self.right)
#            ff.writeTo('\n')
            
#            for item in self.diff_files:
#             ff.writeTo(item)
#             ff.writeTo('\n')
          
  
    def generateDiffReport(self): # Report on self and subdirs recursively
        self.report()
        for sd in self.subdirs.values():
            sd.generateDiffReport()

    methodmap = dict(subdirs=step04_FindDiffCommonFilesInSubDirectories,
                     same_files=step03_FindDiffCommonFiles, diff_files=step03_FindDiffCommonFiles, funny_files=step03_FindDiffCommonFiles,
                     common_dirs = step02_Difffiles_CommonFiles, common_files=step02_Difffiles_CommonFiles, common_funny=step02_Difffiles_CommonFiles,
                     common=step01_FindCommonName, left_only=step01_FindCommonName, right_only=step01_FindCommonName,
                     left_list=step02_FindAll, right_list=step02_FindAll)

    def __getattr__(self, attr):
        if attr not in self.methodmap:
            raise AttributeError(attr)
        self.methodmap[attr](self)
        return getattr(self, attr)

def compareFiles(a, b, common, shallow=True):
    res = ([], [], [])
    for x in common:
        ax = os.path.join(a, x)
        bx = os.path.join(b, x)
        result = _compare(ax, bx, shallow)
        res[result].append(x)
    return res

def compare(f1, f2, shallow=True):
    s1 = _sig(os.stat(f1))
    s2 = _sig(os.stat(f2))
    if s1[0] != stat.S_IFREG or s2[0] != stat.S_IFREG:
        return False
    
    if shallow and s1 == s2:
        return True
    if s1[1] != s2[1]:
        diffFilesWithLines(f1,f2)
        return False

    outcome = _cache.get((f1, f2, s1, s2))
    if outcome is None:
        outcome = doCompare(f1, f2)
        if len(_cache) > 100:      # limit the maximum size of the cache
            clear_cache()
        _cache[f1, f2, s1, s2] = outcome
    return outcome

def _compare(a, b, sh, abs=abs, compare=compare):
    try:
#        diffFilesWithLines(a,b)
        print (a,b)
        return not abs(compare(a, b, sh))
    except OSError:
        return 2
    
def diffFilesWithLines(a,b):
        with open(a, 'r') as file0:
            with open(b, 'r') as file1:
                diff = difflib.unified_diff(
                file0.readlines(),
                file1.readlines(),
                fromfile=b,
                tofile=a)

                file0.close()
                file1.close()
                _cache.clear()
                ff.writeTo(a)
                ff.writeTo(b)
                for line in diff:
                   sys.stdout.write(line)
                   ff.writeDiff(line);

           
# Return a copy with items that occur in skip removed.
#
def _filter(flist, skip):
    return list(filterfalse(skip.__contains__, flist))


# CompareUtils Usage
#
def startCompare():
    global ff
    ff = HtmlUtils('report.html')
     
    options, args = getopt.getopt(sys.argv[1:], 'r')
    if len(args) != 2:
        raise getopt.GetoptError('need exactly two args', None)
    dd = CompareUtils(args[0],args[1])
    print("Diff Report")
    dd.generateDiffReport()
    ff.openWebbrowser()
    

        
if __name__ == '__main__':
    startCompare()
    