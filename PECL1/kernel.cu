#include "device_launch_parameters.h"
#include <time.h>
#include <stdlib.h>
#include <stdio.h>


int main()
{

    cudaStatus = cudaDeviceReset();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaDeviceReset failed!");
        return 1;
    }

    return 0;
}

// Helper function for using CUDA to add vectors in parallel.

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
	while (matriz[r] == 0) {
		r = rand() % 16;
	}

	int opcion = rand() % 100;
	if (opcion <= 60) {
		matriz[r] = 2;
	}
	else {
		matriz[r] = 4;
	}
	/////////////////////////////
	int j = rand() % 16;
	while (matriz[j] == 0) {
		j = rand() % 16;
	}
	
	opcion = rand() % 100;
	if (opcion <= 60) {
		matriz[r] = 2;
	}
	else {
		matriz[r] = 4;
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