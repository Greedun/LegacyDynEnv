# patchelf.sh
# chmod +x patchelf.sh # 외부에서 진행

chmod +x target
chmod +x ld.so
chmod +x libc.so.6

patchelf --set-interpreter ./ld.so target
patchelf --replace-needed libc.so.6 ./libc.so.6 target

# print
echo "> ldd target"
ldd target
echo ""
echo "> strings target | grep GLIBC"
strings target | grep GLIBC