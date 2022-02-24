###
 # @Description: 
 # @Version: 
 # @Autor: Yunfei
 # @Date: 2021-04-21 22:54:05
 # @LastEditors: Yunfei
 # @LastEditTime: 2021-04-23 22:36:10
### 
set -e


xxd -u -a -g 1 -c 16 -s $1 -l 512 80m.img