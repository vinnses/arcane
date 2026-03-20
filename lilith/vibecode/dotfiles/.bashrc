# ~/.bashrc — sources ~/.bashrc.d/*.sh

case $- in
    *i*) ;;
      *) return;;
esac

for f in ~/.bashrc.d/*.sh; do
    [ -f "$f" ] && . "$f"
done
