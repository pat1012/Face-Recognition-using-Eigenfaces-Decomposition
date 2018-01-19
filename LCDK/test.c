#include <stdio.h>
#include <stdlib.h>
#include <cstring>
#include <string.h>
#include <math.h>
#include "L138_LCDK_aic3106_init.h"
#include "evmomapl138_gpio.h"
#include "m_mem.h"
#include "bmp.h"

#define W 75
#define H 100
#define L 7500 // L=W*H
#define M 25 //number of faces in training set for one person
#define N 1 //number of people in training set

#define ustd 80
#define um 100

char* inputPath; // the path of
int inputImage[L]; //L
#pragma DATA_SECTION(inputImage,".EXT_RAM")
float inputMean=0.0;
float inputStd=0.0;
float inputOmega[M];
float distants1[M];

float temp;

float mean1[W*H]; // mean image of person 1
#pragma DATA_SECTION(mean1,".EXT_RAM")
float u1[L*M]; // u of person1
#pragma DATA_SECTION(u1,".EXT_RAM")
float omega1[M*M]; // omega of person1
#pragma DATA_SECTION(omega1,".EXT_RAM")

int i,j,k;

float min=0;
float max=0;
int person=1;
int threshold=28000;

interrupt void interrupt4(void) // interrupt service routine
{
	output_left_sample(0);
	return;
}

int main()
{
	FILE *fm1;
	printf("\nbegin\n");
	fm1=fopen("m.txt","r" );   // read the mean img file of person 1
	for (i=0;i<(W*H);i++)
	{fscanf(fm1,"%f",&mean1[i]);}fclose(fm1);
	FILE *fu1;
	fu1 = fopen("u.txt","r"); // read the u file of person 1
	for(i=0;i<(L*M);i++)
	{fscanf(fu1,"%f",&u1[i]);}fclose(fu1);
	FILE *fom1;
	fom1=fopen("omega.txt","r"); // read the omega file of person 1
	for(i=0;i<(M*M);i++)
	{fscanf(fom1,"%f",&omega1[i]);}fclose(fom1);

	char inputFileName[20];
	FILE *input;
	int count=0;
	while (count<10)
	{
		// read input image
		printf("\nType the input file name:\n");
		scanf("%s",inputFileName);
		printf("\nloading input image...\n");
		input=fopen(inputFileName,"r" );
		for (i=0;i<(W*H);i++)
			fscanf(input,"%d",&inputImage[i]);
		fclose(input);
		printf("\ndone loading image\n");

		// !!!!normailze input image
		// get the mean of inputImage
		for (i=0;i<L;i++)
			inputMean=inputMean+inputImage[i];
		inputMean=inputMean/L;
		printf("\ndone1\n");
		// get the std of inputImage
		for (i=0;i<L;i++)
		{
			temp=inputImage[i]-inputMean;
			inputStd=inputStd+temp*temp;
		}
		printf("\ndone2\n");
		inputStd=sqrt(inputStd/L);

		for (i=0;i<L;i++)
			inputImage[i]=(inputImage[i]-inputMean)*ustd/inputStd+um;
		// done normailization*******************************************
		printf("\ndone3\n");

		
		// compute the weight of the input image
		temp=0;
		for (i=0;i<M;i++)
		{
			for (j=0;j<L;j++)
				temp=temp+u1[i*L+j]*(inputImage[j]-mean1[j]);
			inputOmega[i]=temp;
			temp=0;
		}
		printf("\ndone4\n");

		// compute the distances between the input image and each library image
		temp=0;
		for (i=0;i<M;i++)
		{
			for (j=0;j<M;j++)
				temp=temp+(inputOmega[j]-omega1[i*M+j])*(inputOmega[j]-omega1[i*M+j]);
			distants1[i]=temp;
			temp=0;
		}

		// find the smallest and largest distance to decide if the person is in the library
		max=distants1[0];
		min=distants1[0];
		for (i=0;i<M;i++)
		{
			if(min>distants1[i])
			{
				min=distants1[i];
				person=i+1;
			}
			if(max<distants1[i])
			{
				max=distants1[i];
			}
		}

		max=sqrt(max);
		min=sqrt(min);
		if(max>threshold)
			printf("Person not in library.\n");
		else
			printf("Result: person %d\n",person);


		count++;
		printf("\ndone10\n");
	}

	//*****************************************************************************************************
	L138_initialise_intr(FS_8000_HZ,ADC_GAIN_0DB,DAC_ATTEN_0DB,LCDK_LINE_INPUT);
	 while(1);
}
