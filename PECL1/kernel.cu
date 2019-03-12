#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <time.h>
#include <stdlib.h>
#include <stdio.h>
#include <iostream>

using namespace std;

void showMatriz(int matriz[], int anchura);
int * generateMatriz();
void generateSeeds(int matriz[],int cantidad);
bool checkFull(int matriz[], int tamano);

cudaError_t cudaStatus;
bool partida_enCurso = true;

__global__ void mov_upK(int *matriz, int anchura, int altura) {

	int x = threadIdx.x;

	int *vector = (int*)malloc(sizeof(int)*anchura*altura);
	for (int i = 0; i < anchura*altura; i++)
	{
		vector[i] = 0;
	}

	int *aux = (int*)malloc(sizeof(int)*anchura*altura);
	for (int i = 0; i < anchura*altura; i++)
	{
		aux[i] = 0;
	}


	int posicion_Vector = 0;
	for (int i = 0; i < altura; i++)
	{
		if (matriz[i*anchura + x] != 0) {
			vector[posicion_Vector] = matriz[i*anchura + x];
			posicion_Vector++;
		}
	}

	int posicion_aux = 0;
	for (int j = 0; j < altura; j++)
	{
		if (vector[j] == vector[j+1])
		{
			aux[posicion_aux] = vector[j] * 2;
			j++;
		}
		else
		{
			aux[posicion_aux] = vector[j];
		}
		
		posicion_aux++;
	}
	
	for (int k = 0; k < altura; k++)
	{
		if (!aux[k])
		{
			aux[k] = 0;
		}
	}

	for (int i = 0; i < altura; i++)
	{
		matriz[i*anchura + x] = aux[i];
	}
}


cudaError_t move_up(int *matriz, int ancho, int alto) {
	cudaError_t cudaStatus;

	int *dev_m;

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

	cudaStatus = cudaMemcpy(dev_m, matriz, ancho*alto *sizeof(int), cudaMemcpyHostToDevice);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMemcpy failed!");
		goto Error;
	}

	mov_upK <<< 1,ancho  >>> (dev_m,ancho,alto);

	cudaStatus = cudaGetLastError();
	if (cudaStatus != cudaSuccess)
	{
		fprintf(stderr, "Error en mov_upK");
		goto Error;
	}

	cudaStatus = cudaMemcpy(matriz, dev_m, ancho*alto *sizeof(int), cudaMemcpyDeviceToHost);
	if (cudaStatus != cudaSuccess)
	{
		fprintf(stderr, "Error en memcpy to host de mov_upK");
		goto Error;
	}

Error:
	cudaFree(dev_m);

	return cudaStatus;
}

__global__ void mov_downK(int *matriz, int anchura, int altura) {
	int x = threadIdx.x;

	int *vector = (int*)malloc(sizeof(int)*anchura*altura);
	for (int i = 0; i < anchura*altura; i++)
	{
		vector[i] = 0;
	}

	int *aux = (int*)malloc(sizeof(int)*anchura*altura);
	for (int i = 0; i < anchura*altura; i++)
	{
		aux[i] = 0;
	}

	int posicion_Vector = 0;
	for (int i = altura - 1; i >= 0; i--)
	{
		if (matriz[i*anchura + x] != 0) {
			vector[posicion_Vector] = matriz[i*anchura + x];
			posicion_Vector++;
		}
	}

	int posicion_aux = 0;
	for (int j = 0; j < altura; j++)
	{
		if (vector[j] == vector[j + 1])
		{
			aux[posicion_aux] = vector[j] * 2;
			j++;
		}
		else
		{
			aux[posicion_aux] = vector[j];
		}
		posicion_aux++;
	}

	for (int k = 0; k < altura; k++)
	{
		if (!aux[k])
		{
			aux[k] = 0;
		}
	}
			
	for (int i = 0; i < altura; i++)
	{
		matriz[(altura-1-i)*anchura + x] = aux[i];
	}
}

cudaError_t move_down(int *matriz, int ancho, int alto) {
	cudaError_t cudaStatus;

	int *dev_m;

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

	cudaStatus = cudaMemcpy(dev_m, matriz, ancho*alto * sizeof(int), cudaMemcpyHostToDevice);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMemcpy failed!");
		goto Error;
	}

	mov_downK << < 1, ancho >> > (dev_m, ancho, alto);

	cudaStatus = cudaGetLastError();
	if (cudaStatus != cudaSuccess)
	{
		fprintf(stderr, "Error en mov_upK");
		goto Error;
	}

	cudaStatus = cudaMemcpy(matriz, dev_m, ancho*alto * sizeof(int), cudaMemcpyDeviceToHost);
	if (cudaStatus != cudaSuccess)
	{
		fprintf(stderr, "Error en memcpy to host de mov_upK");
		goto Error;
	}

Error:
	cudaFree(dev_m);

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
	srand(time(NULL));

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
		generateSeeds(matriz, 5);
		showMatriz(matriz, 4);
		printf("Hacia donde quieres mover?(w/a/s/d): ");
		cin >> movimiento;
		switch (movimiento)
		{
		case 'w':
			cudaStatus = move_up(matriz,ancho,alto);
		case 'a':
		case 's':
			cudaStatus = move_down(matriz, ancho, alto);
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

void generateSeeds(int matriz[],int cantidad)
{
	for (int i = 0; i < cantidad; i++)
	{
		int r = rand() % 16;
		while (matriz[r] != 0) {
			r = rand() % 16;
		}

		int opcion = rand() % 100;
		if (opcion <= 50) {
			matriz[r] = 2;
		}
		else if (opcion <= 80 && opcion > 50) {
			matriz[r] = 4;
		}
		else {
			matriz[r] = 8;
		}
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