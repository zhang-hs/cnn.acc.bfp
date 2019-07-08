interface-pc过程：

./vgg.sh	
//向fpga写入64张图片，启动fgpa进行分类

./rd.data.sh	
//读回fpga返回数据，即分类结果，该返回值为分类结果在synset.words.txt(标签列表)中的位置

ll data/rd.file.bin	
//查看文件rd.file.bin的信息，该文件即fpga返回分类结果，可通过文件的建立时间来判断是否是刚返回的结果，以及结果是否返回完

./fpga.data.check 
-c data/fc8.output.batch64.fp32.bin 
-f data/rd.file.bin	
//将fpga分类结果与caffe分类结果对比，-c 后为在电脑端运行的分类结果

vi com_log.txt	
//查看详细对比结果

./classify.batch64 -f data/rd.file.bin 
-c data/fc8.output.batch64.fp32.bin -l data/synset.words.txt
//将rd.file.bin对照synset.words.txt，导出实际结果(标签名)，并与caffe结果对比

vi label-log-fpga.txt
//查看fpga的实际分类结果

