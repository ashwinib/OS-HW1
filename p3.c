#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<stddef.h>
#include<pthread.h>
#include<sys/time.h>
#define BILLION  1000L;

char* word;

int findText(char *string){	
char *temp;
int count=0;
temp=string;
while(temp!=NULL){
	//printf("\nLooking for * %s* in *%s*",word,temp);
	temp=strstr(temp,word);
	if(temp!=NULL){
		count++;
		temp=&(temp[1]);
	}
}
//printf("\nReturning count : %d",count);
return count;
}

int main(int argc, char **argv){

int noOfBlocks=5,count=0,i,counts[100];
long lSize,halfBufSize,fSize;
char *buffer[100],*message;
size_t result,overlap;
FILE *pFile=stdin;
pthread_t thread[100];
int (*p)(char *string)=0;
p=findText;
int status,iter;
struct timespec start, stop;
long accum;

word = argv[1];
// obtain file size:
  fseek (pFile , 0 , SEEK_END); 
  fSize = ftell (pFile);
  rewind (pFile);
  overlap = strlen(word)-1;

//Iterate for 100 threads.
for(iter=1;iter<101;iter++){
noOfBlocks=iter;count=0;

    if( clock_gettime( CLOCK_REALTIME, &start) == -1 ) {
      perror( "clock gettime" );
      return EXIT_FAILURE;
    }

//Decide number of blocks/threads, decide lSize=blocksize
  lSize=fSize/noOfBlocks;
  halfBufSize= fSize-(lSize*(noOfBlocks-1));
  //printf("\noverlap = %ld",-1*(long int)overlap);//DEBUG
  //printf("\n**im here**");  //DEBUG
  //printf("\nBolckSize: %ld",lSize);

//Allocate Buffer and spawn thread
for(i=0;i<noOfBlocks;i++){
	if(i==noOfBlocks-1 && noOfBlocks!=1){
		//printf("\nReached Last Buffer");  //DEBUG
		buffer[i]=  (char*) malloc (sizeof(char)*(size_t)halfBufSize);
	}
	else
		buffer[i]=  (char*) malloc (sizeof(char)*(((size_t)lSize)+overlap));
	if (buffer[i]== NULL) {fputs ("\nMy Memory error",stderr); exit (2);}

	result = fread (buffer[i],lSize+overlap,1,pFile);
	if(!(i==noOfBlocks-1 && noOfBlocks!=1)){
		fseek(pFile,-1*(long int)overlap,SEEK_CUR);
	}	
	//printf("\nresult %Zu-%Zu fsize : %ld",sizeof(buffer[i]),sizeof(char)*(size_t)lSize,lSize); //DEBUG
	if (result != 1 && i!=noOfBlocks-1) {fputs ("\nMy Reading error",stderr); exit (3);}
	//else printf("\nRead block i=%d",i);//DEBUG

	status = pthread_create(&(thread[i]), NULL, (void*)p, buffer[i]);
	/*if(status==0)		//DEBUG
		printf("\nCreate Successful");
	else
		printf("\nCreate UN- Successful");*/
}

//Join 
for(i=0;i<noOfBlocks;i++){//handle last blockp
	//printf("\ni=%d",i);//DEBUG
	pthread_join(thread[i],(void*)&counts[i]);
	//printf("\nim hereafter join : %d",counts[i]);//DEBUG
	count+=counts[i];
	free(buffer[i]);
}


if( clock_gettime( CLOCK_REALTIME, &stop) == -1 ) {
      perror( "clock gettime" );
      return EXIT_FAILURE;
    }

    accum = //( stop.tv_sec - start.tv_sec )
              ( stop.tv_nsec - start.tv_nsec )
                /BILLION;
    //printf( "%lf\n", accum );

  printf("\nblockSize = %ld\tnoOfThread = %d \tmatchCount = %d\t time = %ld",lSize,iter,count,accum);
//printf("\n%d,%ld",iter,accum);
  fseek(pFile,0,SEEK_SET);
}
printf("\nFinal Count = %d ",count);
}
