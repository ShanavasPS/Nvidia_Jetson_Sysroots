# Nvidia_Jetson_Sysroots

This contains scripts to generate device specific sysroots for different Nvidia Jetson devices.
These sysroots can be used to cross compile applications for these devices in a different host machine.

These can also be used to build third party libraries which might be difficult to build in target devices, for eg; OpenCV

### **AGX Orin**

Running the below scripts creates a sysroot archive for `AGX Orin`.

```sh
./build-sysroot-nvidia-jetson-agx-orin.sh
```

### **AGX Xavier**

Running the below scripts creates a sysroot archive for `AGX Xavier`

```sh
./build-sysroot-nvidia-jetson-agx-xavier.sh
```

### **Nano**

Running the below scripts creates a sysroot archive for `Nano`

```sh
./build-sysroot-nvidia-jetson-nano.sh
```
