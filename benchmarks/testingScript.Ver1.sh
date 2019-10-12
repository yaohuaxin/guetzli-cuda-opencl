#
# Configurations
#
NUMBER_OF_GPU=4
PROCESS_NUMBER_ON_EACH_GPU=4

image_input_path=../../dataset/images/eligible_files
#image_input_path=../../dataset/images/eligible_files_testing

#output_folder_path=output.shm
output_folder_path=output.HDD

#images_string=$(ls $image_input_path/*.jpg)
#echo $images_string

#
# run guetzli with parapllel processes
#
PROCESS_NUMBER=$(( NUMBER_OF_GPU * PROCESS_NUMBER_ON_EACH_GPU ))
echo "Use process number: $PROCESS_NUMBER"

#images_array=(`echo $images_string | sed 's/ /\n/g'`)
images_array=( $(ls $image_input_path/*.jpg) )

file_number=${#images_array[@]}
echo "file_number: $file_number"

#for image in ${images_array[*]}
#do
#    echo $image
#done

file_number_per_process=$(( file_number / PROCESS_NUMBER ))
echo "file_number_per_process: $file_number_per_process"

file_number_per_process_top=$(( (file_number+PROCESS_NUMBER-1) / PROCESS_NUMBER ))
echo "file_number_per_process_top: $file_number_per_process_top"

file_number_not_processed=$(( file_number - file_number_per_process*PROCESS_NUMBER ))
echo "file_number_not_processed: $file_number_not_processed"

testing(){
    local CPU_ID=$1
    local GPU_ID=$2
    local files_per_process=$3
	
	#echo "Processing on CPU $CPU_ID, GPU $GPU_ID: $files_per_process"
	
    image_count=0
    local start_time=$SECONDS
    
    #while :     #forever
    for image in ${files_per_process[*]}
    do 
        image_count=$(($image_count + 1))
        #echo $image

        file_name=$(basename $image)
        #echo $file_name
        CUDA_VISIBLE_DEVICES=$GPU_ID  numactl --cpunodebind=$CPU_ID --localalloc ./guetzli --quality 90 --cuda $image $output_folder_path/$file_name > /dev/null 2>&1
        
        if [ $? -ne 0 ]; then
            echo "Error when processing: $image"
        fi
        
    done
    
    duration=$(( SECONDS - start_time ))
    echo "Process ($$, $BASHPID), (CPU_ID: $CPU_ID, GPU_ID: $GPU_ID): Image number processed: $image_count; Duration: $duration (seconds)."
}


CPUs=(0 0 8 8)
GPUs=(0 1 2 3)

start_time_total=$SECONDS

process_id=0
while [ $process_id -lt $PROCESS_NUMBER ]; do
    #echo ${images_array[@]:$((file_number_per_process * process_id)):$file_number_per_process}
    if [ $process_id -lt $file_number_not_processed ]; then
        files_per_process=${images_array[@]:$((file_number_per_process_top*process_id)):$file_number_per_process_top}
    else
        files_per_process=${images_array[@]:$((file_number_per_process_top*file_number_not_processed + file_number_per_process*(process_id-file_number_not_processed))):$file_number_per_process}
    fi
    
    #echo 'Processing:' "$files_per_process"
    
    CPU_GPU_index=$(( process_id % NUMBER_OF_GPU ))
    
    #echo "CPU_GPU_index: $CPU_GPU_index, CPU: ${CPUs[$CPU_GPU_index]}, GPU: ${GPUs[$CPU_GPU_index]}"
    
    testing ${CPUs[$CPU_GPU_index]} ${GPUs[$CPU_GPU_index]} "$files_per_process" &
    
    process_id=$((process_id + 1))
done


wait
duration=$(( SECONDS - start_time_total ))

echo "Job duration: $duration"
