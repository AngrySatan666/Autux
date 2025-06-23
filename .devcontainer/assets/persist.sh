#!/data/data/com.termux/files/usr/bin/bash

persist () {  
    adb shell setprop service.adb.tcp.port 5555  
    sleep 3  
    adb shell stop adbd  
    sleep 3  
    adb shell start adbd  
    sleep 3  
}  
  
check () {  
    adb shell netstat -tnlp | grep -q ":5555"  
}  

# Get the current port
CURRENT_PORT=$(adb shell getprop service.adb.tcp.port | tr -d '\r')

if [[ "$CURRENT_PORT" == "5555" ]]; then  
    if check; then  
        echo "✅ ADB Success"  
    fi  
else  
    persist  
    CURRENT_PORT=$(adb shell getprop service.adb.tcp.port | tr -d '\r')
    
    if [[ "$CURRENT_PORT" == "5555" ]]; then  
        if check; then  
            echo "✅ ADB Success after persistence!"  
        else  
            echo "❌ ADB Failed even after persistence!"  
        fi  
    else  
        echo "❌ ADB Failed to set TCP port to 5555!"  
    fi  
fi