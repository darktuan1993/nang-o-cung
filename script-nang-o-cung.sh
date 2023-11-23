﻿########### VARIABLE ###########
arrayMenu=("Tạo phân disk mới và mount" "Nâng cấp dung lượng" "Thoát")
mapfile -t vg_names < <(vgdisplay | awk '/VG Name/ {print $3}')
capacityNumber=""

function echo_space(){
    echo " "
}
function echo_dongke(){
    echo "----------------------------------------"
}
function exit_va_clear(){
    exit
    sleep 1
    clear
}
########### END VARIABLE ###########


# Danh sách menu
function list_menu() {
    for ((i = 0; i < ${#arrayMenu[@]}; i++)); do
        echo "----                  $((i + 1)). ${arrayMenu[$i]}          "
    done
}
# Lấy thông tin disk
function lay_thong_tin_disk() {
    clear
    echo " "
    echo "============================ Check thông tin phân vùng df -HT ==================================="
    df -hT
    echo " "
    echo "============================ Check thông tin đĩa lsblk ============================"
    lsblk
}

# Tạo Phân vùng trong fdisk
function create_partition_disk() {
    nameDisk=$1
    capacityDisk=$2
    partitionNumber=$3
    
    echo "Tên disk: $nameDisk"
    echo "Dung lượng: $capacityDisk"
    echo "Partition : $partitionNumber"
    # Nếu nhập số của phân vùng dạng sdb1,sdb2
    if [ -n "$3" ]; then
        echo_dongke
        echo "ĐANG TRONG QUÁ TRÌNH TẠO Ổ CỨNG"
        echo_dongke
        fdisk "/dev/$1" <<EOF
        n
        p
        $partitionNumber

        +${capacityDisk}G
        t

        8e
        w
EOF
        echo "TẠO PARTITION $nameDisk$partitionNumber THÀNH CÔNG"
    else
        # NHẤN ENTER LUÔN
        echo_dongke
        echo "ĐANG TRONG QUÁ TRÌNH TẠO Ổ CỨNG"
        echo_dongke
        fdisk "/dev/$1" <<EOF
        n
        p
        $partitionNumber

        +${capacityDisk}G
        t

        8e
        w
EOF
        echo_dongke
        echo "TẠO PARTITION THÀNH CÔNG"
        echo_dongke
    fi
    
}

# Tạo volume group VG
function create_volume_group() {
    read -p "Nhập tên volume group muốn tạo : " nameOfVolumeGroup
    # Check volume group
    # echo " Danh sách volume group:  ${vg_names[@]}  "
    for vg_name in "${vg_names[@]}"; do
        if [ "$vg_name" == "$nameOfVolumeGroup" ]; then
            found=true
            break
        fi
    done
    if [ "$found" == true ]; then
        echo "Tên $nameOfVolumeGroup đã được sử dụng rồi !"
    else
        echo "Tên $nameOfVolumeGroup có thể sử dụng"
        read -p "Nhập tên phân vùng disk muốn tạo (nhập dạng sdbx) : " partition_number
        vgcreate $nameOfVolumeGroup /dev/$partition_number
    fi
}

# Check điều kiện tạo ổ cứng và tạo ổ cứng
function conditionCreateDisk {
    while true; do
        read -p "Nhập số của phân vùng $nameOFdisk (chỉ cần nhập số), NÊN Enter ko nhập gì thì mặc định theo thứ tự (ví dụ: $nameOFdisk 1, $nameOFdisk 2,..): " partitionNumber
        
        if ls /dev | grep -q $nameOFdisk$partitionNumber && [ -n "$partitionNumber" ]; then
            echo "Có ổ cứng này rồi người anh em ơi"
        else
            
            # Check chỉ được nhập số
            function is_number() {
                [[ $1 =~ ^[0-9]+$ ]]
            }
            
            while true; do
                read -p "Nhập dung lượng theo GB: " capacityNumber
                
                if is_number "$capacityNumber"; then
                    break
                else
                    echo "Nhập số thôi người anh em"
                fi
            done
            
            if [ -n "$partitionNumber" ]; then
                # Đẩy config theo số phân vùng được nhập vào fdisk
                create_partition_disk $nameOFdisk $capacityNumber $partitionNumber
                # create_volume_group
                echo " "
                echo "LIST LSLBK MỚI , VUI LÒNG KIỂM TRA LẠI NHÉ: "
                echo " "
                lsblk
                echo "----------- DONE -----------  "
                exit_va_clear
            else
                # Nếu không nhập gì $partitionNumber là rỗng, Mặc định sẽ theo thứ tự là sdb1 sdb2 sdb3
                create_partition_disk $nameOFdisk $capacityNumber $partitionNumber
                # create_volume_group
                echo " "
                echo "LIST LSLBK MỚI , VUI LÒNG KIỂM TRA LẠI NHÉ: "
                echo " "
                lsblk
                echo "----------- DONE -----------  "
                exit_va_clear
            fi
            
        fi
    done
}

# Đồng ý tạo ổ cứng
function accept_create() {
    read -p "Bạn có đồng ý tạo ổ đĩa mới không? (y/n): " choice
    case $choice in
        [yY])
            conditionCreateDisk
        ;;
        
        [nN])
            exit_va_clear
        ;;
    esac
}

# MAIN FUNCTIONS
function tao_sdxY() {
    echo " "
    read -p "Nhập tên ổ đĩa muốn tạo (nhập dạng sdx) : " nameOFdisk
    # Kiểm tra ký tự nhập
    if [ ${#nameOFdisk} -lt 3 ]; then
        echo "Nhập sai tên rồi phèn, làm gì có ổ nào là $nameOFdisk, tự thoát sau 2s "
        sleep 2
        exit
    else
        if ls /dev | grep -q $nameOFdisk; then
            # Nếu tồn tại ổ cứng thì check tiếp dung lượng
            mapfile -t size_free_space < <(parted /dev/$nameOFdisk unit s print free | awk '/Free Space/ {print $3}' | sed 's/s$//')
            clear
            lay_thong_tin_disk
            echo_space
            array_length=${#size_free_space[@]}
            # echo $array_length
            if [ "$array_length" = 0 ]; then
                echo_dongke
                echo "Có thể tạo phân vùng trên ổ cứng này !"
                echo_dongke
                accept_create
            else
                disk_space_sector_default="${size_free_space[0]}"
                disk_space_sector="${size_free_space[1]}"
                
                case $array_length in
                    1)
                        if [ "$disk_space_sector_default" -gt 5000 ]; then
                            echo_dongke
                            echo "Dung lượng vẫn còn bạn có thể tạo ổ cứng"
                            echo_dongke
                            accept_create
                        else
                            echo_space
                            echo "HẾT DUNG LƯỢNG Ổ CỨNG $nameOFdisk"
                            echo_space
                            exit
                        fi
                    ;;
                    
                    2 | *)
                        
                        if [ "$disk_space_sector" -gt 5000 ]; then
                            echo_dongke
                            echo "Dung lượng vẫn còn bạn có thể tạo ổ cứng"
                            echo_dongke
                            accept_create
                            
                        else
                            echo_space
                            echo "HẾT DUNG LƯỢNG Ổ CỨNG $nameOFdisk"
                            echo_space
                            exit
                        fi
                    ;;
                    
                esac
            fi
            
        else
            # Không tồn tại
            echo "Không có ổ cứng nào là $nameOFdisk"
        fi
    fi
    
}



######################## Menu script #########################
echo "---------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------"
echo "----                                                                         ----"
echo "----                                                                         ----"
echo "----                                TOOL Ổ CỨNG                              ----"
echo "----                    For distribution Linux: Ubuntu/RHEL/CentOS           ----"
echo "----                                  **ver0.1**                             ----"
echo "----                                                                         ----"
echo "----                             *create by Daz9_Tu4n*                       ----"
echo "----                                                                         ----"
list_menu
echo "----                                                                         ----"
echo "---------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------"
echo_space
read -p "Vui lòng chọn option [1-${#arrayMenu[@]}] : " choice
case $choice in
    1)
        clear
        lay_thong_tin_disk
        tao_sdxY
    ;;
    2)
        exit_va_clear
    ;;
    *)
        clear
        exit_va_clear
    ;;
esac