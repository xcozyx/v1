import platform
import psutil
import time
import json
from datetime import datetime, timedelta
import cpuinfo
import distro
import os
import requests
import subprocess

# Path for storing network usage data
DATA_FILE = '/mnt/data/network_usage.json'

def get_initial_network_usage():
    net_io = psutil.net_io_counters()
    return {"bytes_sent": net_io.bytes_sent, "bytes_recv": net_io.bytes_recv}

def load_network_usage():
    if os.path.exists(DATA_FILE):
        with open(DATA_FILE, 'r') as file:
            return json.load(file)
    else:
        initial_data = {"daily": get_initial_network_usage(), "monthly": get_initial_network_usage()}
        save_network_usage(initial_data)
        return initial_data

def save_network_usage(data):
    os.makedirs(os.path.dirname(DATA_FILE), exist_ok=True)
    with open(DATA_FILE, 'w') as file:
        json.dump(data, file)

def calculate_bandwidth_usage(initial, current):
    bytes_sent = current['bytes_sent'] - initial['bytes_sent']
    bytes_recv = current['bytes_recv'] - initial['bytes_recv']
    total_usage = bytes_sent + bytes_recv
    return total_usage / (1024 ** 3)  # Convert to GB

def get_network_usage():
    current_usage = get_initial_network_usage()
    saved_usage = load_network_usage()
    daily_usage = calculate_bandwidth_usage(saved_usage['daily'], current_usage)
    monthly_usage = calculate_bandwidth_usage(saved_usage['monthly'], current_usage)
    return daily_usage, monthly_usage

def update_network_usage():
    current_time = datetime.now()
    current_day = current_time.day
    current_month = current_time.month

    saved_usage = load_network_usage()
    saved_time = datetime.fromtimestamp(os.path.getmtime(DATA_FILE))
    saved_day = saved_time.day
    saved_month = saved_time.month

    if current_day != saved_day:
        saved_usage['daily'] = get_initial_network_usage()
    if current_month != saved_month:
        saved_usage['monthly'] = get_initial_network_usage()
    
    save_network_usage(saved_usage)

def get_ip_info():
    try:
        response = requests.get("https://ipinfo.io")
        data = response.json()
        isp = data.get("org", "")
        if isp.startswith("AS"):
            isp = " ".join(isp.split(" ")[1:])  # Remove AS prefix
        return {
            "IP Address": data.get("ip"),
            "ISP": isp,
            "Region": data.get("region"),
            "City": data.get("city"),
            "Date": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        }
    except requests.RequestException:
        return {
            "IP Address": "N/A",
            "ISP": "N/A",
            "Region": "N/A",
            "City": "N/A",
            "Date": "N/A"
        }

def check_service_status(service_name):
    try:
        result = subprocess.run(['systemctl', 'is-active', service_name], capture_output=True, text=True)
        return result.stdout.strip()
    except Exception as e:
        return f"Error checking status: {e}"

def get_system_info():
    # Get CPU usage
    cpu_usage = psutil.cpu_percent(interval=1)  # Get current CPU usage as a percentage

    # Get OS and kernel info
    os_name = f"{distro.name()} {distro.version()}"
    kernel_version = platform.release()

    # Get RAM info
    total_ram = psutil.virtual_memory().total / (1024 ** 3)  # Convert to GB
    used_ram = psutil.virtual_memory().used / (1024 ** 3)    # Convert to GB
    ram_percentage = psutil.virtual_memory().percent

    ram_usage_str = f"{used_ram:.2f} GB / {total_ram:.2f} GB ({ram_percentage:.1f}%)"

    # Get uptime info
    uptime_seconds = time.time() - psutil.boot_time()
    uptime_str = str(timedelta(seconds=uptime_seconds)).split('.')[0]

    # Get disk usage info
    disk_usage = psutil.disk_usage('/')
    total_disk = disk_usage.total / (1024 ** 3)  # Convert to GB
    used_disk = disk_usage.used / (1024 ** 3)    # Convert to GB
    disk_percentage = disk_usage.percent

    disk_usage_str = f"{used_disk:.2f} GB / {total_disk:.2f} GB ({disk_percentage:.1f}%)"

    # Get service status
    nginx_status = check_service_status('nginx')
    xray_status = check_service_status('xray')

    # Prepare system info data
    system_data = [
        ("Operating System", os_name),
        ("Kernel Version", kernel_version),
        ("RAM Usage", ram_usage_str),
        ("Disk Usage", disk_usage_str),
        ("CPU Usage", f"{cpu_usage:.2f} %"),
        ("Uptime Server", uptime_str),
        ("Nginx Status", nginx_status),
        ("Xray-core Status", xray_status)
    ]

    return system_data

def display_combined_info(system_data, ip_info, network_data):
    # Print System, IP, and Network Usage Information together
    print("+-------------------------------------------------------+")
    print("|       <> Script Xray Only <> mod by Sonzai X <>       |")
    print("+-------------------------------------------------------+")

    # Display system information
    for item in system_data:
        print(f"> {item[0]:<25} : {item[1]:<10}")

    # Display IP information
    for key, value in ip_info.items():
        print(f"> {key:<25} : {value:<10}")

    # Display network information
    for network_item in network_data:
        print(f"> {network_item[0]:<25} : {network_item[1]:<10}")

    print("+-------------------------------------------------------+")

if __name__ == "__main__":
    update_network_usage()
    system_data = get_system_info()
    ip_info = get_ip_info()
    daily_bandwidth_usage, monthly_bandwidth_usage = get_network_usage()

    # Prepare network info data with "GB" for usage
    network_data = [
        ("Daily Data Usage", f"{daily_bandwidth_usage:.2f} GB"),
        ("Monthly Data Usage", f"{monthly_bandwidth_usage:.2f} GB")
    ]

    # Display combined info
    display_combined_info(system_data, ip_info, network_data)
