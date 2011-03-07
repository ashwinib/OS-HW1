#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<stddef.h>
#include<sys/time.h>
#define BILLION  1000L;

__global__ void findText(char *dbuffer,char* dword,int *dcount,int overlap,int blockSize,int noOfThreads){
int i = blockDim.x * blockIdx.x + threadIdx.x;
char *temp;
int ix;
char *s1,*s2;
int length,cvalue=0;
char *temp1,*temp2;int tempi;
if(i < noOfThreads){
//printf("\ni=%d Looking for %s in %d blocks-->",i,word,noOfThreads);
//printf("");
	temp = dbuffer+(blockSize*i);
//printf("\nIncrementing by : %d",blockSize*i);
	length=blockSize+overlap;
	for (ix = 0; dword[ix] != '\0'; ix++) ;
	//printf("\nwordlength : %d\n",length);
	while(temp!=NULL){
		s1=temp;s2=dword;
		


while(length > 0){

        if(*s1!=*s2)
                s1++;
        else
        {
	        temp1=++s1;temp2=s2+1;tempi=ix-1;
        	while(tempi>0){
	                if(*temp1==*temp2)
        	        {temp2++;temp1++;}
                	else
               		{
                	        break;
               		}
	                tempi--;
       		}
 	       if(tempi==0){
       		        temp = s1;

			break;
       		}
        }
	length--;
}
if(length==0)
temp =  NULL;


		if(temp != NULL){
			cvalue++;
			dcount[i]=dcount[i]+1;
		}
	}

	//dcount[i] = cvalue;
//	__syncthreads();

}
}

int main(int argc, char **argv){

//Initialize things to pass
char *buffer,*dbuffer;
char *word,*dword;
int overlap;
int blockSize;
int noOfThreads ;
int *count,*dcount,totalcount = 0;
long fSize;
int i,threadsPerBlock,blocksPerGrid,var;
FILE *pFile = stdin; 
struct timespec start, stop; 
long accum;

	word = argv[1];


	/*  Initialize Buffer */
	fseek(pFile , 0, SEEK_END);
	fSize = ftell(pFile);
	rewind (pFile);
	buffer = (char*) malloc (sizeof(char)*fSize);
	if (buffer== NULL) {fputs (" \n My Memory error",stderr); exit (2);}
	if(fread(buffer,fSize*sizeof(char),1,pFile)!=1){fputs(" \n My Memory Err",stderr); exit(2);}


	/*Initialize grid numbers*/ 
	blocksPerGrid = 1;

for (var =1 ; var < 512; var++){
	totalcount=0;
	threadsPerBlock = var;
	noOfThreads = threadsPerBlock * blocksPerGrid;
	blockSize=(long)fSize/noOfThreads;
	//printf("\nnoOfThreads  = %d blockSize = %ld\n fileSize = %ld",noOfThreads,blockSize,fSize);

	/*Initialize count*/ 
	count = (int*) malloc (sizeof(int) * noOfThreads);
	//hdbgarr = (int*) malloc (sizeof(int) * noOfThreads);
	
	/*Initialize word*/ 
	cudaMalloc((void**)&dword,sizeof(char)*(strlen(word)));
	cudaMalloc((void**)&dbuffer,fSize*sizeof(char));
	cudaMalloc((void**)&dcount,sizeof(int)*noOfThreads);

	/*  Initialize overlap which is one less than strlen */
	overlap = strlen(word)-1;


	for(i=0;i<noOfThreads;i++) count[i]=0;
	cudaMemcpy(dword,word,sizeof(char)*strlen(word),cudaMemcpyHostToDevice);
	cudaMemcpy(dbuffer,buffer,fSize*sizeof(char),cudaMemcpyHostToDevice);
	/*Copy count*/ 
	cudaMemcpy(dcount,count,(sizeof(int)*noOfThreads),cudaMemcpyHostToDevice);


	//printf(" \n \n All Initialized");

if( clock_gettime( CLOCK_REALTIME, &start) == -1 ) {
      perror( "clock gettime" );
      return EXIT_FAILURE;
}


	findText<<<blocksPerGrid,threadsPerBlock>>>(dbuffer,dword,dcount,overlap,blockSize,noOfThreads);//passing noofthredas-1 as padding nt handles yet

	cudaThreadSynchronize();

if( clock_gettime( CLOCK_REALTIME, &stop) == -1 ) {
      perror( "clock gettime" );
      return EXIT_FAILURE;
    }
	cudaMemcpy(count,dcount,(sizeof(int)*noOfThreads),cudaMemcpyDeviceToHost);
	

//printf("%s\n\n",buffer);
	//printf("\nCounts");
	for(i=0;i<noOfThreads;i++){
		//printf("%d ",count[i]);
		totalcount += count[i];
	}
	//printf(" \n Total Count = %d",totalcount);

	accum = (stop.tv_nsec - start.tv_nsec)/BILLION;
	printf("\n %d, %ld",var,accum);

	//free(word);
	free(count);
	cudaFree(dword);
	cudaFree(dbuffer);
	cudaFree(dcount);
}
	printf(" \n Total Count = %d",totalcount);
	free(buffer);
}
