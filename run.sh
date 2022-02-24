###
 # @Description: 
 # @Version: 
 # @Autor: Yunfei
 # @Date: 2021-04-03 16:48:15
 # @LastEditors: Yunfei
 # @LastEditTime: 2021-05-08 09:38:58
### 

set -e


make all
cd command
make
make install
cd ..
make clean
make buildimg
bochs