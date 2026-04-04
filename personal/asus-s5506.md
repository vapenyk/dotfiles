## Asus VIVOBOOK 15 OLED s5506

add kernel parameter for xe graphics

# scx_loader (via CachyOS Kernel Manager)

Select sched-ext scheduler: "scx_lavd" and set auto

# limine (what i use)

sudo $EDITOR /etc/default/limine

add this "i915.force_probe=!7d55 xe.force_probe=7d55"

and 

```bash 
sudo limine-mkinitcpio
```
