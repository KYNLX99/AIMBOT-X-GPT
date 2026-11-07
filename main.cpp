#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <dirent.h>
#include <sys/uio.h>
#include <unistd.h>
#include <cstring>

int get_pid_by_name(const char* process_name) {
    DIR* dir = opendir("/proc");
    struct dirent* entry;
    int pid = -1;
    if (dir != nullptr) {
        while ((entry = readdir(dir)) != nullptr) {
            if (entry->d_type == DT_DIR) {
                std::string pid_str = entry->d_name;
                if (pid_str.find_first_not_of("0123456789") == std::string::npos) {
                    std::string cmdline_path = "/proc/" + pid_str + "/cmdline";
                    std::ifstream cmdline(cmdline_path);
                    std::string cmdline_content;
                    if (std::getline(cmdline, cmdline_content, '\0')) {
                        if (cmdline_content.find(process_name) != std::string::npos) {
                            pid = std::stoi(pid_str);
                            break;
                        }
                    }
                }
            }
        }
        closedir(dir);
    }
    return pid;
}

bool write_memory(pid_t pid, uintptr_t address, const void* data, size_t len) {
    struct iovec local[1];
    struct iovec remote[1];
    local[0].iov_base = const_cast<void*>(data);
    local[0].iov_len = len;
    remote[0].iov_base = reinterpret_cast<void*>(address);
    remote[0].iov_len = len;
    ssize_t nwritten = process_vm_writev(pid, local, 1, remote, 1, 0);
    return nwritten == static_cast<ssize_t>(len);
}

int main() {
    if (getuid() != 0) {
        std::cerr << "[-] UID bukan 0. Jalankan sebagai root (su).\n";
        return 1;
    }
    const char* target_pkg = "com.dts.freefireth";
    int pid = get_pid_by_name(target_pkg);
    if (pid == -1) {
        std::cerr << "[-] Target tidak berjalan.\n";
        return 1;
    }
    std::cout << "[+] Root diverifikasi. Target PID: " << pid << "\n";
    uintptr_t target_address = 0x7500000000; 
    uint8_t patch[] = { 0x00, 0x00, 0x80, 0x52 };
    if (write_memory(pid, target_address, patch, sizeof(patch))) {
        std::cout << "[+] Wrote " << sizeof(patch) << " bytes to 0x" << std::hex << target_address << "\n";
        std::cout << "[+] Stashed.\n";
    } else {
        std::cerr << "[-] Gagal menulis memori.\n";
        return 1;
    }
    return 0;
}