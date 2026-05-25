if [[ -z "$1" ]]; then
    echo "Error: Please provide a target shader."
    echo "Usage: $0 <shader_name>"
    exit 1
fi

qsb --glsl "100 es,120,150" -o $1.frag.qsb $1.frag
