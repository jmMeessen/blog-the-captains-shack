+++
author = ""
comments = true
date = "2016-10-22T22:29:59+01:00"
draft = true
image = ""
menu = ""
share = true
slug = "rpi-piglow-container"
tags = ["raspberry", "hypriot", "pimoroni"]
title = "Add some glitter to RPi Docker containers"

+++

With limited investment, the Raspberry Pi is a great platform to touch, learn and demonstrate many concepts of modern computing. Docker has very rapidely found its way on the RPi, mainly with the help of the [Hypriot](http://blog.hypriot.com/) distribution. I use a flock of RPi to demonstrate and help visualize many Docker concepts. 

With its hardware interfacing capabilities, the Raspberry Pi is also a very popular IOT platform. Docker could have the same "mass innovation" enabling effect as for mainstream computing. "build, ship and run" opens indeed interesting perspectives in the field of IOT. 

While prepairing a training lab with my flock of RPis, I wondered if I could demonstrate that aspect of Docker. These are some notes about my experiments.

[Pimoroni](https://shop.pimoroni.com/) builds several devices that plug on the  Raspberry Pi GPIO. They are well designed, reasonably priced and often useful. The software support is good. Thus a good starting point for hassle free experiments.

### Containing the Piglow

The first candidate was the Piglow. 

![piglow](https://cdn.shopify.com/s/files/1/0174/1800/products/PiGlow-3_1024x1024.gif)

This small PCB is plugged on the GPIO header and steered via one of the serial line available on this interface, called I2C. The Pimoroni supplied example python code shows how to control the individual LED. A good sample to start with was the CPU load visualizer (`cpu.py`). 

I first made it work directly on my RPI2 with the Hypriot ditribution. It is important to load the relevent kernel modules (`i2c-dev` and `i2c-bcm2708` in the `/etc/modules`. Although not mentioned in the documentation, I had to enable them in the `/boot/config.txt` by adding the line `dtparam=i2c1=on`. These files look like this on my systems. 

/etc/modules ```
# /etc/modules: kernel modules to load at boot time.
#
# This file contains the names of kernel modules that should be loaded
# at boot time, one per line. Lines beginning with "#" are ignored.

snd_bcm2835

i2c-dev
i2c-bcm2708
```

```
hdmi_force_hotplug=1
enable_uart=1

# camera settings, see http://elinux.org/RPiconfig#Camera
start_x=1
disable_camera_led=1
gpu_mem=128

dtparam=i2c1=on
```

Once the hardware is accessible, I created a container image based on the [`alexellis2/python-gpio-arm:armv6`](https://github.com/alexellis/docker-arm/tree/master/images/armv6/python-gpio-arm) image by Docker Cap'tain Alex Ellis. I then load the necessary components for Python support of the Piglow. See hereafter the Docker file used. 

```docker
# Pimoroni's Piglow enabled image for Raspberry Pi

FROM alexellis2/python-gpio-arm:armv6

MAINTAINER Jean-Marc MEESSEN <jean-marc@meessen-web.org>

WORKDIR /root/
RUN apt-get -q update && \
    apt-get -qy install python-dev python-pip python-smbus python-psutil gcc make && \
    apt-get -qy remove python-dev gcc make && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get -qy clean all
```