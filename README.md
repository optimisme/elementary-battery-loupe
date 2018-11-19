# Battery Loupe App

### Read and examine your battery stats.

Shows information about the health of your battery.

![screenshot](Screenshot.png)

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
