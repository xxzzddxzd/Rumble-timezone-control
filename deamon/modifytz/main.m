#import <Foundation/Foundation.h>
NSString* getTargetZone(int tarhour) {
    // 获取所有时区的名称
    NSArray *timeZones = [NSTimeZone knownTimeZoneNames];
    
    // 创建一个日期格式化器
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm"];
    
    // 获取当前日期和时间
    NSDate *now = [NSDate date];
    
    // 保存符合条件的时区
    NSMutableArray *matchingTimeZones = [NSMutableArray array];
    
    for (NSString *timeZoneName in timeZones) {
        // 设置时区
        NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:timeZoneName];
        [formatter setTimeZone:timeZone];
        
        // 获取当前时区的时间
        NSString *timeString = [formatter stringFromDate:now];
        
        // 获取小时和分钟部分
        NSArray *timeComponents = [timeString componentsSeparatedByString:@":"];
        NSInteger hour = [[timeComponents firstObject] integerValue];
        NSInteger minute = [[timeComponents lastObject] integerValue];
        
        // 判断时间是否在23:00到23:30之间
        if (hour == tarhour ) {
            [matchingTimeZones addObject:timeZoneName];
        }
    }
    if (tarhour == 23) {
        return  [matchingTimeZones objectAtIndex:0];
    }
    
    //遍历时区，选出分钟数为59的
    int minMins = 59;
    NSString * minZone = nil;
    for (NSString *timeZoneName in matchingTimeZones) {
        // 设置时区
        NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:timeZoneName];
        [formatter setTimeZone:timeZone];
        NSString *timeString = [formatter stringFromDate:now];
        NSArray *timeComponents = [timeString componentsSeparatedByString:@":"];
        NSInteger minute = [[timeComponents lastObject] integerValue];
        if (minute == 59){
            minZone = timeZoneName;
        }
    }
    
    return  minZone;
}
//NSString * getTargetZone(){
//    int min=0;
//    NSString *timeZones = getTimeZonesWithCurrentTimeBetween23_00And23_15(0);
//    while (!timeZones) {
//        min+=1;
//        timeZones = getTimeZonesWithCurrentTimeBetween23_00And23_15(min);
//    }
//    return  timeZones;
//}

void writeToFile(NSString * content){
    NSString *filePath = @"zonenow"; // 修改为实际的文件路径
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:filePath]) {
        // 删除已存在的文件
        NSError *error = nil;
        [fileManager removeItemAtPath:filePath error:&error];
        if (error) {
            NSLog(@"Failed to delete existing file: %@", error);
            return;
        }
    }
    
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
    if (!fileHandle) {
        [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
        fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
    }
    
    NSData *data = [content dataUsingEncoding:NSUTF8StringEncoding];
    [fileHandle writeData:data];
    return ;
}

NSString * displayTimeByZone(NSString * zone){
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm"]; // 设置日期格式只显示小时和分钟
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:zone]];
    return [dateFormatter stringFromDate:[NSDate date]];
}

void displayAllTimeZones() {
    // 获取所有时区的名称
    NSArray *timeZones = [NSTimeZone knownTimeZoneNames];
    
    // 创建一个日期格式化器
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm"]; // 设置日期格式只显示小时和分钟
    
    // 获取当前日期和时间
    NSDate *now = [NSDate date];
    
    for (NSString *timeZoneName in timeZones) {
        // 设置时区
        NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:timeZoneName];
        [dateFormatter setTimeZone:timeZone];
        
        // 格式化当前日期和时间
        NSString *timeString = [dateFormatter stringFromDate:now];
        
        // 打印时区名称和当前时间
        NSLog(@"Time Zone: %@ - Current Time: %@", timeZoneName, timeString);
    }
}

NSString * readTimeZoneNow(){
    NSString *symbolicLinkPath = @"/var/db/timezone/localtime";
    
    // 创建文件管理器
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // 错误对象
    NSError *error = nil;
    
    // 获取符号链接的目标路径
    NSString *targetPath = [fileManager destinationOfSymbolicLinkAtPath:symbolicLinkPath error:&error];
    
    if (targetPath != nil) {
        //        NSLog(@"Symbolic link %@ points to %@", symbolicLinkPath, [targetPath componentsSeparatedByString:@"/var/db/timezone/zoneinfo/"][1]);
        return [targetPath componentsSeparatedByString:@"/var/db/timezone/zoneinfo/"][1];
    } else {
        NSLog(@"Error reading symbolic link %@: %@", symbolicLinkPath, [error localizedDescription]);
    }
    return nil;
}



void setZoneFile(NSString * tarzone){
    NSString * tarzoneFullPath = [NSString stringWithFormat:@"/var/db/timezone/zoneinfo/%@",tarzone];
    NSString *localtimePath = @"/var/db/timezone/localtime";
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    if ([fileManager fileExistsAtPath:tarzoneFullPath]) {
        // 删除 /var/db/timezone/localtime 文件
        BOOL removed = [fileManager removeItemAtPath:localtimePath error:&error];
        if (!removed && error) {
            NSLog(@"Error deleting localtime file: %@", [error localizedDescription]);
            return;
        }
        NSLog(@"Localtime file deleted successfully.");
        
        // 创建符号链接
        BOOL created = [fileManager createSymbolicLinkAtPath:localtimePath withDestinationPath:tarzoneFullPath error:&error];
        if (created) {
            NSLog(@"Symbolic link created successfully.");
        } else {
            NSLog(@"Error creating symbolic link: %@", [error localizedDescription]);
        }
    } else {
        NSLog(@"Timezone file not found: %@", tarzoneFullPath);
    }
}

#import <dlfcn.h>
typedef int (*my_system) (const char *str);
int call_system(const char *str){
    
    //动态库路径
    char *dylib_path = "/usr/lib/libSystem.dylib";
    //打开动态库
    void *handle = dlopen(dylib_path, RTLD_GLOBAL | RTLD_NOW);
    if (handle == NULL) {
        //打开动态库出错
        NSLog(@"call error");
        fprintf(stderr, "%s\n", dlerror());
    } else {
        //获取 system 地址
        my_system system = dlsym(handle, "system");
        
        //地址获取成功则调用
        if (system) {
            
            int ret = system(str);
            return ret;
        }
        dlclose(handle); //关闭句柄
    }
    
    return -1;
}
#import <Foundation/Foundation.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <unistd.h>
//使用zxtouch的功能调起app
//11com.blizzard.arc
static int runApp() {
    // 创建 socket
    int clientSocket = socket(AF_INET, SOCK_STREAM, 0);
    if (clientSocket == -1) {
        NSLog(@"Failed to create socket");
        return -1;
    }
    
    // 设置服务器地址结构体
    struct sockaddr_in server_addr;
    server_addr.sin_len = sizeof(server_addr);
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(6000);
    server_addr.sin_addr.s_addr = inet_addr("127.0.0.1"); // localhost
    
    // 连接服务器
    if (connect(clientSocket, (struct sockaddr *)&server_addr, sizeof(server_addr)) == -1) {
        NSLog(@"Failed to connect to server");
        close(clientSocket);
        return -1;
    }
    
    // 发送消息
    const char *msg = "11com.blizzard.arc";
    ssize_t bytesSent = send(clientSocket, msg, strlen(msg), 0);
    if (bytesSent == -1) {
        NSLog(@"Failed to send message");
        close(clientSocket);
        return -1;
    }
    
    // 关闭 socket 连接
    close(clientSocket);
    return 0;
}


int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSString * tarzone = getTargetZone(23);
        setZoneFile(tarzone);
        while (1) {
            NSString * nowzone = readTimeZoneNow();
            tarzone = getTargetZone(22);
            while (!tarzone) {
                sleep(10);
                tarzone = getTargetZone(22);
            }
            NSLog(@"now: %@ - %@, tar: %@ - %@", nowzone, displayTimeByZone(nowzone), tarzone, displayTimeByZone(tarzone));
            for (int i=0; i<12; i++) {
                call_system("killall Rumble");
                sleep(5);
            }
            setZoneFile(tarzone);
            sleep(10);
            runApp();
            sleep(5);
        }
    }
    return 0;
}
