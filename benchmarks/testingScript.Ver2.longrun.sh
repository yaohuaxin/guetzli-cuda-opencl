#
# Configurations
#
NUMBER_OF_GPU=4
PROCESS_NUMBER_ON_EACH_GPU=8

CPUs=(0 0 8 8)
GPUs=(0 1 2 3)

#CPUs=(0 0 0 0 8 8 8 8)
#GPUs=(0 1 2 3 4 5 6 7)

image_input_path=../../dataset/images/eligible_files
#image_input_path=../../dataset/images/eligible_files_testing
#image_input_path=../../dataset/images/eligible_files_profile_80Images
#image_input_path=../../dataset/images/eligible_files_profile_8Images

#output_folder_path=output.shm
output_folder_path=output.HDD

PROCESS_NUMBER=$(( NUMBER_OF_GPU * PROCESS_NUMBER_ON_EACH_GPU ))
echo "Use process number: $PROCESS_NUMBER"

#
# Divide dataset into subfolders
#
images_array=( $(ls $image_input_path/*.jpg) )
file_number=${#images_array[@]}
echo "file_number: $file_number"

file_number_per_process=$(( file_number / PROCESS_NUMBER ))
echo "file_number_per_process: $file_number_per_process"

file_number_per_process_top=$(( (file_number+PROCESS_NUMBER-1) / PROCESS_NUMBER ))
echo "file_number_per_process_top: $file_number_per_process_top"

file_number_not_processed=$(( file_number - file_number_per_process*PROCESS_NUMBER ))
echo "file_number_not_processed: $file_number_not_processed"

process_id=0
division="/"
while [ $process_id -lt $PROCESS_NUMBER ]; do
    input_dir="$image_input_path$division$process_id"
    rm -rf $input_dir
    mkdir $input_dir
	
    pushd $input_dir > /dev/null
    
    if [ $process_id -lt $file_number_not_processed ]; then
        files_per_process=${images_array[@]:$((file_number_per_process_top*process_id)):$file_number_per_process_top}
        for image in ${files_per_process[*]}
        do
            #echo $(basename $image)
            ln -s "../"$(basename $image)
        done
    else
        files_per_process=${images_array[@]:$((file_number_per_process_top*file_number_not_processed + file_number_per_process*(process_id-file_number_not_processed))):$file_number_per_process}
        for image in ${files_per_process[*]}
        do
            #echo $(basename $image)
            ln -s "../"$(basename $image)
        done
    fi
    
    popd > /dev/null

    process_id=$(( process_id+1 ))
done

#
# Prepare the output directories
#
process_id=0
division="/"
while [ $process_id -lt $PROCESS_NUMBER ]; do
    output_dir="$output_folder_path$division$process_id"
    rm -rf $output_dir
    mkdir -p "$output_dir"

    process_id=$(( process_id+1 ))
done

#
# Pross wrapper for runnig the workloader
#
testing(){
    local CPU_ID=$1
    local GPU_ID=$2
    local input_file_or_directory=$3
    local output_file_or_directory=$4
    
    image_count=$(ls $input_file_or_directory | wc -l )
    
    echo "Process ($$, $BASHPID), (CPU $CPU_ID, GPU $GPU_ID), input :$input_file_or_directory, output: $output_file_or_directory"

    local start_time=$SECONDS
    
    CUDA_VISIBLE_DEVICES=$GPU_ID  numactl --cpunodebind=$CPU_ID --localalloc ./guetzli --quality 90 --cuda --runforever $input_file_or_directory $output_file_or_directory #> /dev/null 2>&1
    
    duration=$(( SECONDS - start_time ))
    echo "Process ($$, $BASHPID), (CPU $CPU_ID, GPU $GPU_ID): Image processed: $image_count; Duration: $duration (seconds)."
}
    
#
# start the running
#

start_time_total=$SECONDS

process_id=0
while [ $process_id -lt $PROCESS_NUMBER ]; do
    input_folder_path_current_process="$image_input_path$division$process_id$division"
    output_folder_path_current_process="$output_folder_path$division$process_id$division"
    #echo $output_folder_path_current_process
	
    #CUDA_VISIBLE_DEVICES=0  numactl --cpunodebind=0 --localalloc ./guetzli --quality 90 --cuda $image_input_path $output_folder_path_current_process
	
    CPU_GPU_index=$(( process_id % NUMBER_OF_GPU ))
    testing ${CPUs[$CPU_GPU_index]} ${GPUs[$CPU_GPU_index]} $input_folder_path_current_process $output_folder_path_current_process &
	
    process_id=$(( process_id+1 ))
done


wait
duration=$(( SECONDS - start_time_total ))

echo "Job duration: $duration Seconds."