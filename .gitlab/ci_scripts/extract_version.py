import re
release_ver_regex = re.compile(r'(?:(?:\d+|[a-z])[.-]){2,}(?:\d+|((a(lpha)?|b(eta)?|c|r(c|ev)?|pre(view)|dev?)\d*)?)')
short_ver_regex = re.compile(r'(?:(?:\d+|[a-z])[.-]){2,}(?:\d+)')
with open('godot/code/Settings.gd', 'r') as f:
    file_contents = f.read()
# The full version, including alpha/beta/rc tags
full_version = release_ver_regex.search(file_contents).group()
# The short X.Y version
short_version = short_ver_regex.search(file_contents).group()
print(full_version)
#print(short_version)