#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/file.h>
#include <string.h>
#include <pthread.h>
#include <SDL/SDL.h>
#include <SDL/SDL_thread.h>
#include <SDL/SDL_audio.h>
#include <SDL/SDL_timer.h>
#include <linux/videodev2.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <errno.h>
#include <fcntl.h>
#include <time.h>
#include <sys/time.h>
#include <signal.h>
#include <X11/Xlib.h>
#include <SDL/SDL_syswm.h>
#include <SDL/SDL_ttf.h>
#include <getopt.h>
#include "v4l2uvc.h"
#include "gui.h"
#include "utils.h"
#include "color.h"

/* Fixed point arithmetic */
#define FIXED Sint32
#define FIXED_BITS 16
#define TO_FIXED(X) (((Sint32)(X))<<(FIXED_BITS))
#define FROM_FIXED(X) (((Sint32)(X))>>(FIXED_BITS))
#define INCPANTILT 64 
//FPGA HOST
#define DMA_TO_DEVICENAME "/dev/xdma0_h2c_0"
#define DMA_FROM_DEVICENAME "/dev/xdma0_c2h_0"
#define WRITE_ADDRESS 0
#define READ_ADDRESS 2147483648
#define WRITE_OFFSET 0
#define READ_OFFSET 0
#define WRITE_SIZE 401408
#define READ_SIZE 8192
#define COUNT 1
// #define FPGA_FILE "./data/rd.file.bin"
#define EXP_FILE 	"./data/exp.txt"
#define LABEL_FILE "./data/synset.words.txt"
#define REF_LABEL_FILE "./data/batch.label.bin"
#define RESULTS_SIZE 30
#define LINE_HEIGHT	25
//time interval(ms)
#define GETPIC_INTERVAL 500 //1000
#define READ_AFTER_WRITE 400 //700
#define CHECK_AFTER_READ 100 //300 
//SDL gui
typedef enum action_gui {
    A_SCREENSHOT,
    A_SCREENSHOTAUTO,
	A_QUIT,
	A_VIDEO
} action_gui;
typedef struct act_title {
	action_gui action;
	char * title;
} act_title;
typedef struct key_action_t {
    SDLKey key;
    action_gui action;
} key_action_t;
key_action_t keyaction[] = {
    {SDLK_g, A_SCREENSHOT},
    {SDLK_a, A_SCREENSHOTAUTO},
    {SDLK_q, A_QUIT},
    {SDLK_m, A_VIDEO}  
};
act_title title_act[4] ={
   { A_SCREENSHOT,"Take a Picture"},
   { A_SCREENSHOTAUTO,"Take Pictures Automatically"},
   { A_QUIT,"Quit Happy, Bye Bye:)"},
   { A_VIDEO,"Obtaining"}
};
//SDL
struct vdIn *videoIn;
const SDL_Color RGB_Black   = { 0, 0, 0 };  
const SDL_Color RGB_Red     = { 255, 0, 0 };  
const SDL_Color RGB_White   = { 255, 255, 255 };  
const SDL_Color RGB_Yellow  = { 255, 255, 0 }; 
static Uint32 SDL_VIDEO_Flags = SDL_ANYFORMAT | SDL_DOUBLEBUF | SDL_RESIZABLE;	//sdl初始化标识字
//线程数据
struct pt_data {
    SDL_Surface **ptscreen;
    SDL_Event *ptsdlevent;
    SDL_Rect *drect;
    struct vdIn *ptvideoIn;
    unsigned int numpic;
    SDL_mutex *affmutex;
} ptdata;
//function declare
action_gui GUI_whichbutton(int x, int y, SDL_Surface * pscreen, struct vdIn *videoIn);
action_gui GUI_keytoaction(SDLKey key);
static int eventThread(void *data);		//线程事件
//main    
int main(int argc, char *argv[])
{
	//SDL
	SDL_Surface *pscreen;
	SDL_Surface *pText = NULL;
	SDL_Overlay *overlay;
	SDL_Rect drect;
	SDL_Rect mSrect;
	SDL_Rect mDrect;
	SDL_Rect mTrect;
	SDL_Event sdlevent;
	SDL_Thread *mythread;
	SDL_mutex *affmutex;
	TTF_Font *font;
	//FPGA HOST
	int cmd_opt;
	char *dma_to_device = DMA_TO_DEVICENAME;
	char *dma_from_device = DMA_FROM_DEVICENAME;
	uint32_t write_address = WRITE_ADDRESS;
	uint32_t read_address = READ_ADDRESS;
	uint32_t write_size = WRITE_SIZE;
	uint32_t read_size = READ_SIZE;
	uint32_t write_offset = WRITE_OFFSET;
	uint32_t read_offset = READ_OFFSET;
	uint32_t count = COUNT;
	// char *fpga_file = FPGA_FILE;
	char *label_file = LABEL_FILE;
	//video
	int status;
	//修改计时方式
	uint32_t currtime_get;
	uint32_t lasttime_get;
	uint32_t currtime_read;
	unsigned int numgetpic = 0;//捕获的图片数量
	unsigned int numread = 0;//从FPGA读取结果次数
	//char read_done = 1;
	unsigned char *p = NULL;
	const char *videodevice = NULL;
	const char *mode = NULL;
	int format = V4L2_PIX_FMT_YUYV;
	int grabmethod = 1;
	int width = 640;
	int height = 480;
	int fps = 30;
	char *avifilename = NULL;
	char* exp_data = (char*)malloc(8192*sizeof(uint8_t));
	char* fpga_data = (char*)malloc(1000*sizeof(uint16_t));
	char* ref_label_data = (char*)malloc(4);
	char *results = NULL;//分配动态内存
	char *prob_top5 = NULL;
	results = (char *)malloc(5*RESULTS_SIZE*sizeof(char));
	prob_top5 = (char *)malloc(5*10*sizeof(char));
	strcpy(results, "VGG Classifier");
	strcpy(prob_top5, "\0");

	printf("dma_to_device = %s, write_address = 0x%08x, write_size = 0x%08x, write_offset = 0x%08x, write_count = %u\n", dma_to_device, write_address, write_size, write_offset, count);

	FILE *exp_handle = fopen(EXP_FILE, "rb");
	if(exp_handle==NULL) {
	  printf("ERROR: open exp file.\n");
	  return -1;
	}
	fread(exp_data, 1, 8192, exp_handle);
	fclose(exp_handle);

	FILE *ref_label_handle = fopen(REF_LABEL_FILE, "rb");
	if(ref_label_handle==NULL) {
	  printf("ERROR: open ref label file.\n");
	  return -1;
	}
	fread(ref_label_data, 1, 4, ref_label_handle);
	fclose(ref_label_handle);

    //--------------------- SDL,TTF initialization
	if (SDL_Init(SDL_INIT_VIDEO) < 0) {
		fprintf(stderr, "Couldn't initialize SDL: %s\n", SDL_GetError());
		exit(1);
	}
	if (TTF_Init() < 0) {
		fprintf(stderr, "Couldn't initialize TTF: %s\n", TTF_GetError());
		exit(1);
	}
	font = TTF_OpenFont("FreeSans.ttf",20);
	if (font == NULL)
	{
		fprintf(stderr, "Couldn't open TTF_font: %s\n", TTF_GetError());
		exit(1);
	}
	TTF_SetFontStyle(font, TTF_STYLE_NORMAL);

	//----------------------configurations
	if (!(SDL_VIDEO_Flags & SDL_HWSURFACE))
		SDL_VIDEO_Flags |= SDL_SWSURFACE;
	if (videodevice == NULL || *videodevice == 0) {
			videodevice = "/dev/video0";
		}

	//-----------------------创建sdl显示
	videoIn = (struct vdIn *) calloc(1, sizeof(struct vdIn));
	if (init_videoIn(videoIn, (char *) videodevice, width, height, fps, format, grabmethod, avifilename) < 0)
		exit(1);
	//打开SDL程序窗口(宽，高，位深，flags标志维)，创建surface用来显示视频
	pscreen = SDL_SetVideoMode(videoIn->width+200, videoIn->height, 0,SDL_VIDEO_Flags);
	//负责创建YUV,参数分别是宽度,高度,YUV格式和SDL_Surface，通过overlay输出视频到surface显示
	overlay = SDL_CreateYUVOverlay(videoIn->width, videoIn->height, SDL_YUY2_OVERLAY, pscreen);
	p = (unsigned char *) overlay->pixels[0];
	drect.x = 200;
	drect.y = 0;
	drect.w = pscreen->w;
	drect.h = pscreen->h;
	//results源区域显示大小
	mSrect.x = 0;
	mSrect.y = 0;
	mSrect.w = 200;
	mSrect.h = LINE_HEIGHT;
	//results目的区域显示大小
	mDrect.x = 0;
	mDrect.y = 0;
	mDrect.w = 200;
	mDrect.h = LINE_HEIGHT;
	//results的背景区域
	mTrect.x = 0;
	mTrect.y = 0;
	mTrect.w = 200;
	mTrect.h = videoIn->height;
	
	initLut();		//初始化查找表
	//----------------------初始化线程数据，并创建线程
	ptdata.ptscreen = &pscreen;
	ptdata.ptvideoIn = videoIn;
	ptdata.ptsdlevent = &sdlevent;
	ptdata.drect = &drect;
	affmutex = SDL_CreateMutex();	//创建一个互斥对象
	ptdata.affmutex = affmutex;
	mythread = SDL_CreateThread(eventThread, (void *) &ptdata);		//创建新线程事件

	/* main big loop */
	lasttime_get = SDL_GetTicks();
	while (videoIn->signalquit) {
		//抓取视频数据
		if (uvcGrab(videoIn) < 0) {
			printf("Error grabbing\n");
			break;
		}
		//dispaly the video
		SDL_LockYUVOverlay(overlay);
		memcpy(p, videoIn->framebuffer,
				videoIn->width * (videoIn->height) * 2);
		SDL_UnlockYUVOverlay(overlay);
		SDL_DisplayYUVOverlay(overlay, &drect);
		
		//get picture
		if (videoIn->getPict == 1) { //Take a Picture
			lasttime_get = SDL_GetTicks();
			//get_pictureYV2(videoIn->framebuffer,videoIn->width,videoIn->height);
			pic_to_device(videoIn->framebuffer,224,224,dma_to_device,write_address,write_offset,count,exp_data);
			numgetpic++;
			videoIn->getPict = 0;
			printf("get picture!\n");
		}
		//Take a Picture per 10s
		//if there is a long time(>GETPIC_INTERVAL) before,the first one will be got immediately once "a" is pressed
		else if (videoIn->getPict == 2) { 
			currtime_get = SDL_GetTicks();
			if(currtime_get-lasttime_get >= GETPIC_INTERVAL)
			{
			lasttime_get = currtime_get;
			//get_pictureYV2(videoIn->framebuffer,videoIn->width,videoIn->height);
			pic_to_device(videoIn->framebuffer,224,224,dma_to_device,write_address,write_offset,count,exp_data);
			numgetpic++;
			printf("get picture!\n");
		   }
		}
		currtime_read = SDL_GetTicks();
		if((currtime_read-lasttime_get >= READ_AFTER_WRITE) && (numgetpic-numread == 1))
		{
		 //read classify results from FPGA
		 results_from_device(dma_from_device, read_address, read_size, read_offset, count, fpga_data);
		numread++;
		printf("read classification results from FPGA!\n");
		//清除results
		for (int i = 0; i < 5; i++)
		{
		  memset(results+i*RESULTS_SIZE, '\0', strlen(results+i*RESULTS_SIZE));
		}
		for (int j = 0; j < 5; j++)
		{
		  memset(prob_top5+j*sizeof(float), '\0', strlen(prob_top5+j*sizeof(float)));
		}
		//将rd.file.bin对照synset.words.txt，导出实际结果
		classify_batch(fpga_data, label_file, ref_label_data, results, prob_top5);
		printf("showing classication results!\n");
		//read_done = 1;//time to LockSurface and update results on pscreen,reduce the update times
		} 
		
		//if(read_done)
		{
		//渲染字体
		SDL_FillRect(pscreen,&mTrect, SDL_MapRGB(pscreen->format,0x00,0x00,0x00) );//刷新背景
		//top1
		pText = TTF_RenderText_Solid(font, results, RGB_Red);
		if (NULL != pText)
		{  		
			SDL_BlitSurface(pText,&mSrect,pscreen,&mDrect); 
			SDL_FreeSurface(pText);  
		}
		mDrect.y += LINE_HEIGHT;
		pText = TTF_RenderText_Solid(font, prob_top5, RGB_White);
		if (NULL != pText)
		{  		
			SDL_BlitSurface(pText,&mSrect,pscreen,&mDrect); 
			SDL_FreeSurface(pText);  
		}
		mDrect.y += 2*LINE_HEIGHT;
		//top2
		pText = TTF_RenderText_Solid(font, results+RESULTS_SIZE, RGB_Red);
		if (NULL != pText)
		{  
		 	SDL_BlitSurface(pText,&mSrect,pscreen,&mDrect); 
			SDL_FreeSurface(pText);  
		}
		mDrect.y += LINE_HEIGHT;
		pText = TTF_RenderText_Solid(font, prob_top5+10, RGB_White);
		if (NULL != pText)
		{  		
			SDL_BlitSurface(pText,&mSrect,pscreen,&mDrect); 
			SDL_FreeSurface(pText);  
		}
		mDrect.y += 2*LINE_HEIGHT;
		//top3
		pText = TTF_RenderText_Solid(font, results+2*RESULTS_SIZE, RGB_Red);
		if (NULL != pText)
		{  
		 	SDL_BlitSurface(pText,&mSrect,pscreen,&mDrect); 
			SDL_FreeSurface(pText);  
		}
		mDrect.y += LINE_HEIGHT;
		pText = TTF_RenderText_Solid(font, prob_top5+2*10, RGB_White);
		if (NULL != pText)
		{  		
			SDL_BlitSurface(pText,&mSrect,pscreen,&mDrect); 
			SDL_FreeSurface(pText);  
		}
		mDrect.y += 2*LINE_HEIGHT;
		//top4
		pText = TTF_RenderText_Solid(font, results+3*RESULTS_SIZE, RGB_Red);
		if (NULL != pText)
		{  
		 	SDL_BlitSurface(pText,&mSrect,pscreen,&mDrect); 
			SDL_FreeSurface(pText);  
		}
		mDrect.y += LINE_HEIGHT;
		pText = TTF_RenderText_Solid(font, prob_top5+3*10, RGB_White);
		if (NULL != pText)
		{  		
			SDL_BlitSurface(pText,&mSrect,pscreen,&mDrect); 
			SDL_FreeSurface(pText);  
		}
		mDrect.y += 2*LINE_HEIGHT;
		//top5
		pText = TTF_RenderText_Solid(font, results+4*RESULTS_SIZE, RGB_Red);
		if (NULL != pText)
		{  
		 	SDL_BlitSurface(pText,&mSrect,pscreen,&mDrect); 
			SDL_FreeSurface(pText);  
		}
		mDrect.y += LINE_HEIGHT;
		pText = TTF_RenderText_Solid(font, prob_top5+4*10, RGB_White);
		if (NULL != pText)
		{  		
			SDL_BlitSurface(pText,&mSrect,pscreen,&mDrect); 
			SDL_FreeSurface(pText);  
		}
		//将缓冲在界面显示出来
		mDrect.y -= 13*LINE_HEIGHT;
		SDL_UpdateRect(pscreen,mTrect.x,mTrect.y,mTrect.w,mTrect.h);
		//read_done = 0;
		}

		SDL_LockMutex(affmutex);
		ptdata.numpic = numgetpic;
		SDL_WM_SetCaption(videoIn->status, NULL);
		SDL_UnlockMutex(affmutex);
		SDL_Delay(10);

	}
	SDL_WaitThread(mythread, &status);
	SDL_DestroyMutex(affmutex);

	free(exp_data);
	free(fpga_data);
	free(ref_label_data);
	free(results);
	results = NULL;
	close_v4l2(videoIn);
	free(videoIn);
	destroyButt();
	freeLut();
	TTF_CloseFont(font);
	TTF_Quit();
	printf("Cleanup done. Exiting ...\n");
	SDL_Quit();
}



action_gui
GUI_whichbutton(int x, int y, SDL_Surface * pscreen, struct vdIn *videoIn)
{
    int nbutton, retval;
    FIXED scaleh = TO_FIXED(pscreen->h) / (videoIn->height);
    int nheight = FROM_FIXED(scaleh * videoIn->height);
    if (y < nheight)
	return (A_VIDEO);
    nbutton = FROM_FIXED(scaleh * 32);
    /* 8 buttons across the screen, corresponding to 0-7 extand to 16*/
    retval = (x * 16) / (pscreen->w);
    /* Bottom half of the button denoted by flag|0x10 */
    if (y > (nheight + (nbutton / 2)))
	retval |= 0x10;
    return ((action_gui) retval);
}

action_gui GUI_keytoaction(SDLKey key)
{
	int i = 0;
	while(keyaction[i].key){
		if (keyaction[i].key == key)
			return (keyaction[i].action);
		i++;
	}

	return (A_VIDEO);
}

static int eventThread(void *data)
{
	struct pt_data *gdata = (struct pt_data *) data;
	struct v4l2_control control;
	SDL_Surface *pscreen = *gdata->ptscreen;
	struct vdIn *videoIn = gdata->ptvideoIn;
	SDL_Event *sdlevent = gdata->ptsdlevent;
	SDL_Rect *drect = gdata->drect;
	SDL_mutex *affmutex = gdata->affmutex;
	unsigned int numpic;
	int x, y;
	int mouseon = 0;
	int value = 0;
	int len = 0;
	short incpantilt = INCPANTILT;
	int boucle = 0;
	action_gui curr_action = A_VIDEO;
	while (videoIn->signalquit) {
		SDL_LockMutex(affmutex);
		numpic = gdata->numpic;
		while (SDL_PollEvent(sdlevent)) {	//scan the event queue
			switch (sdlevent->type) {
				case SDL_KEYUP:
					mouseon = 0;
					incpantilt = INCPANTILT;
					boucle = 0;
					break;
				case SDL_KEYDOWN:
					curr_action = GUI_keytoaction(sdlevent->key.keysym.sym);
					if (curr_action != A_VIDEO)
						mouseon = 1;
					break;
				case SDL_VIDEORESIZE:
					pscreen = SDL_SetVideoMode(sdlevent->resize.w,
								sdlevent->resize.h, 0,
								SDL_VIDEO_Flags);
					drect->w = sdlevent->resize.w;
					drect->h = sdlevent->resize.h;
					break;
				case SDL_QUIT:
					printf("\nQuit signal received.\n");
					videoIn->signalquit = 0;
					break;
			}
		}			//end if poll
		SDL_UnlockMutex(affmutex);
		/* traiter les actions */
		value = 0;
		if (mouseon){
			boucle++;
			switch (curr_action) {
				case A_SCREENSHOT:
					SDL_Delay(200);
					videoIn->getPict = 1;
					value = 1;
					break;
				case A_SCREENSHOTAUTO:
					SDL_Delay(200);
					videoIn->getPict = 2;
					value = 1;
					break;
				case A_QUIT:  
					videoIn->signalquit = 0;
					break;
				case A_VIDEO:
					break;
				default:
					break;
			}
			if(!(boucle%10)) // smooth pan tilt method
				if(incpantilt < (10*INCPANTILT))
					incpantilt += (INCPANTILT/4);
			if(value){
				len = strlen(title_act[curr_action].title)+8;
				snprintf(videoIn->status, len,"%s %06d",title_act[curr_action].title,value);
			}
		} 
		else { // mouseon	
			len = strlen(title_act[curr_action].title)+10;
			snprintf(videoIn->status, len,"%s,	%02d pics",title_act[curr_action].title,numpic);
		}
		SDL_Delay(50);
	}				//end main loop

	/* Close the stream capture file */
	if (videoIn->captureFile) {
		fclose(videoIn->captureFile);
		printf("Stopped raw stream capturing to stream.raw. %u bytes written for %u frames.\n",
				videoIn->bytesWritten, videoIn->framesWritten);
	}
	/* Display stats for raw frame stream capturing */
	if (videoIn->rawFrameCapture == 2) {
		printf("Stopped raw frame stream capturing. %u bytes written for %u frames.\n",
				videoIn->rfsBytesWritten, videoIn->rfsFramesWritten);
	}
}

void showresults(SDL_Surface *pText, SDL_Rect mSrect, SDL_Rect mDrect, TTF_Font *font, char *results, SDL_Color color )
{


}
