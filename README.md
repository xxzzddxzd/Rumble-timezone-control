# Rumble timezone control
 
始终保持你的手机时区在23点。

## DAEMON

- 守护进程需要以root启动
- 首次启动时会先找一个任意23时的时区切换过去，随后进入循环。
- 循环内遍历时区，并在某个时区达到22：59分时，杀掉游戏进程，等待1分钟后修改时区并启动游戏
- 自动启动游戏需要zxtouch库的支持。

### 安装方法

- 编译或从release下载、拷贝二进制文件到手机上
- chmod 755 modifytz
- nohup ./modifytz > modifytzlog 2>&1 &

## DYLIB（非必要）

- 钩子让你的游戏启动时检测小时，若小时数不为23，则游戏无法启动。
- 当在游戏内小时数达到23时，也会退出。

### 安装方法

- 拷贝dylib目录下的一对文件到/Library/MobileSubstrate/DynamicLibraries/

## 配合zxtouch实现全部自动
- https://github.com/xuan32546/IOS13-SimulateTouch
