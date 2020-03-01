# ubnt-config

Config & scripts for UBNT/Unifi Routers.




### Usage


```
bash install.sh
```


Tested on EdgeRouter-4 with firmware 2.0.8.


Used and using on ERL, ER-X, ER-4, USG, USG-Pro.



### Maintenance

##### Domain List (dns-list)

```
Format: domain,default-resolver,ipset,hijacked-resolution
```

You can generate dnsmasq config like

```
server=/domain/default-resolver
ipset=/.domain/ipset
address=/.domain/hijacked-resolution

```

Write your own scripts.



##### Route List (route-list)

IP blocks are imported to an IPSET named DST\_STATIC by default, you can modify it in `scripts/post-config.d/20-import-route`.


Configure with your PBR, or you can modify this script for static routing.


Here is how you can get ip blocks:  https://sskaje.me/ip-ranges/

This project is useful to generate a merged ip blocks from autonomous system: https://github.com/sskaje/radb

If you want to merge ip blocks, try https://ip.rst.im/merge/



##### IPSET List (ipset-list)

If you want to add any to ipset by default, add here, format:

```
FILENAME: IPSET_NAME.list
CONTENT: set content line by line

```



