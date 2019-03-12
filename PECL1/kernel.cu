#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <time.h>
#include <stdlib.h>
#include <stdio.h>
#include <iostream>

using namespace std;

void showMatriz(int matriz[], int anchura);
int * generateMatriz();
void generateSeeds(int matriz[]);
bool checkFull(int matriz[], int tamano);

cudaError_t cudaStatus;
bool partida_enCurso = true;

__global__ void mov_upK(int *matriz,int *resultado,int anchura, int altura) {
	int posicion = blockIdx.x*anchura + threadIdx.x;

	int superior = posicion - anchura;

	if (posicion >= anchura)
	{
			if (matriz[posicion] == matriz[superior])
			{
				resultado[superior] = matriz[superior] * 2;
			}
			else if (matriz[superior] == 0)
			{
				resultado[superior] = matriz[posicion];
			}
			/*
			else if (superior - anchura < 0) {
				if (matriz[superior] == matriz[superior - anchura]) {
					_sleep(10);
					matriz[superior] = matriz[posicion];
					matriz[posicion] = 0;
				}
			}*/
	}
}

cudaError_t move_up(int *matriz) {
	cudaError_t cudaStatus;
	
	const int ancho = 4;
	const int alto = 4;

	int *dev_m;
	int *dev_resultado;

	cudaStatus = cudaSetDevice(0);
	if (cudaStatus != cudaSuccess)
	{
		fprintf(stderr, "Error en setdevice");
		goto Error;
	}

	cudaStatus = cudaMalloc((void**)&dev_m, ancho*alto * sizeof(int));
	if (cudaStatus != cudaSuccess)
	{
		fprintf(stderr, "Error en Malloc");
		goto Error;
	}
	cudaStatus = cudaMalloc((void**)&dev_resultado, ancho*alto * sizeof(int));
	if (cudaStatus != cudaSuccess)
	{
		fprintf(stderr, "Error en Malloc");
		goto Error;
	}

	cudaStatus = cudaMemcpy(dev_m, matriz, ancho*alto*sizeof(int), cudaMemcpyHostToDevice);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMemcpy failed!");
		goto Error;
	}

	cudaStatus = cudaDeviceSynchronize();
	if (cudaStatus != cudaSuccess)
	{
		fprintf(stderr, "Error en synchronize de mov_upK");
		goto Error;
	}

	mov_upK <<< 1,ancho*alto  >>> (dev_m,dev_resultado,ancho,alto);

	cudaStatus = cudaDeviceSynchronize();
	if (cudaStatus != cudaSuccess)
	{
		fprintf(stderr, "Error en synchronize de mov_upK");
		goto Error;
	}

	cudaStatus = cudaGetLastError();
	if (cudaStatus != cudaSuccess)
	{
		fprintf(stderr, "Error en mov_upK");
		goto Error;
	}

	cudaStatus = cudaMemcpy(matriz, dev_resultado, ancho*alto*sizeof(int), cudaMemcpyDeviceToHost);
	if (cudaStatus != cudaSuccess)
	{
		fprintf(stderr, "Error en memcpy to host de mov_upK");
		goto Error;
	}

Error:
	cudaFree(dev_m);

	return cudaStatus;
}

__global__ void mov_downK(int * matriz[]) {

}

cudaError_t move_down(int * matriz[]) {
	cudaError_t cudaStatus;
	return cudaStatus;
}

__global__ void mov_leftK(int * matriz[]) {

}

cudaError_t move_left(int * matriz[]) {
	cudaError_t cudaStatus;
	return cudaStatus;
}

__global__ void mov_rightK(int * matriz[]) {

}

cudaError_t move_right(int * matriz[]) {
	cudaError_t cudaStatus;
	return cudaStatus;
}


int main()
{
	cudaError_t cudaStatus;

	int ancho = 4;
	int alto = 4;
	int *matriz;
	matriz = (int*)malloc(ancho*alto * sizeof(int));
	for (int i = 0; i < ancho*alto; i++) {
		matriz[i] = 0;
	}

	while (partida_enCurso) 
	{
		char movimiento = 'p';
		printf("Tablero:\n");
		generateSeeds(matriz);
		showMatriz(matriz, 4);
		printf("�Hacia donde quieres mover?(w/a/s/d): ");
		cin >> movimiento;
		switch (movimiento)
		{
		case 'w':
			cudaStatus = move_up(matriz);
		case 'a':
		case 's':
		case 'd':

		default:
			break;
		}
		//system("CLS");
	}

	

    cudaStatus = cudaDeviceReset();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaDeviceReset failed!");
        return 1;
    }

    return 0;
}

// Metodo que SOLO muestra matrices cuadradas
void showMatriz(int matriz[], int anchura)
{
	for (int i = 0; i < (anchura*anchura); i++) {
		printf("%d	", matriz[i]);
		if ((i + 1) % anchura == 0) {
			printf("\n");
		}
	}
}

int * generateMatriz()
{
	const int ancho = 4;
	const int alto = 4;
	int c[ancho*alto] = { 0 };
	return c;
}

void generateSeeds(int matriz[])
{
	srand(time(NULL));

	int r = rand()%16;
	while (matriz[r] != 0) {
		r = rand() % 16;
	}

	int opcion = rand() % 100;
	if (opcion <= 50) {
		matriz[r] = 2;
	}
	else if (opcion<=80 && opcion>50) {
		matriz[r] = 4;
	}
	else {
		matriz[r] = 8;
	}
	/////////////////////////////
	int j = rand() % 16;
	while (matriz[j] != 0 || j==r) {
		j = rand() % 16;
	}
	
	opcion = rand() % 100;
	if (opcion <= 60) {
		matriz[j] = 2;
	}
	else if (opcion <= 80 && opcion > 50) {
		matriz[j] = 4;
	}
	else {
		matriz[j] = 8;
	}
}

bool checkFull(int matriz[],int tamano) 
{
	for (int i = 0; i < tamano; i++) 
	{
		if (matriz[i] == 0)
		{
			return false;
		}
	}
	return true;
}