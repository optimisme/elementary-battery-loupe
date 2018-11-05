# Persual Battery App
**Build:** 

    meson build --prefix=/usr

**Install:**

    cd build
    ninja
    ninja com.github.optimisme.elementary-battery-loupe-pot
    ninja com.github.optimisme.elementary-battery-loupe-update-po
    sudo ninja install


**Uninstall:**

    sudo ninja uninstall
