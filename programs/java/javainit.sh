#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# Check if a project name was provided
if [ -z "$1" ]; then
    echo "Usage: javainit <project_name>"
    exit 1
fi

PROJECT_NAME="$1"

echo "🚀 Creating Java Ant Project: $PROJECT_NAME"

# 1. Create directory structure
mkdir -p "$PROJECT_NAME/src"
cd "$PROJECT_NAME"

# 2. Generate the build.xml for Ant
cat << EOF > build.xml
<?xml version="1.0" encoding="UTF-8"?>
<project name="$PROJECT_NAME" default="run" basedir=".">

    <property name="src.dir" value="src"/>
    <property name="build.dir" value="build"/>
    <property name="classes.dir" value="\${build.dir}/classes"/>
    <property name="main-class" value="Main"/>

    <target name="clean">
        <delete dir="\${build.dir}"/>
    </target>

    <target name="compile">
        <mkdir dir="\${classes.dir}"/>
        <javac srcdir="\${src.dir}" destdir="\${classes.dir}" includeantruntime="false"/>
    </target>

    <target name="run" depends="compile">
        <java classname="\${main-class}" fork="true">
            <classpath>
                <pathelement location="\${classes.dir}"/>
            </classpath>
        </java>
    </target>

</project>
EOF

# 3. Generate the boilerplate Main.java
cat << EOF > src/Main.java
public class Main {
    public static void main(String[] args) {
        System.out.println("Hello from $PROJECT_NAME!");
    }
}
EOF

echo "✅ Project '$PROJECT_NAME' initialized successfully!"
echo "📂 Run 'cd $PROJECT_NAME' and open Neovim to start."
