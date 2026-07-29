# java — JAVA_HOME for the temurin jdk.
#
# the cask is `temurin@25`, a pinned major version, so this path is as stable as the Brewfile
# entry and can be a literal. it is checked rather than assumed so an uninstalled jdk is a
# silent no-op, per the house guard rule.
#
# ⚠ deliberately NOT `(/usr/libexec/java_home)`. that is an external command, so it forks on
# every shell start including non-interactive ones — measured at 5.7 ms, over half of this
# config's entire ~10 ms interactive budget — to produce a value that only changes when the
# jdk is upgraded. when temurin moves to 26, edit this line and the Brewfile together.
#
# only JAVA_HOME is set, deliberately. macos ships stub binaries at /usr/bin/{java,javac,
# jshell,jar,...} that dispatch to whatever jdk java_home resolves, so the toolchain is
# already reachable on $PATH. what was missing is the variable — gradle, maven, scons' java
# tooling and every jvm launcher read JAVA_HOME and ignore the stubs.

set -l jdk /Library/Java/JavaVirtualMachines/temurin-25.jdk/Contents/Home

if test -d $jdk
    set -q JAVA_HOME; or set -gx JAVA_HOME $jdk
end
