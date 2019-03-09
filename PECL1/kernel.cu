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

__global__ void mov_up(int * matriz[]) {

}

cudaError_t move_up(int * matriz[]) {

}

__global__ void mov_down(int * matriz[]) {

}

cudaError_t move_down(int * matriz[]) {

}

__global__ void mov_left(int * matriz[]) {

}

cudaError_t move_left(int * matriz[]) {

}

__global__ void mov_right(int * matriz[]) {

}

cudaError_t move_right(int * matriz[]) {

}

int main()
{
	const int ancho = 4;
	const int alto = 4;
	int matriz[ancho*alto] = { 0 };

	while (partida_enCurso) 
	{
		char movimiento = 'p';
		printf("Tablero:\n");
		showMatriz(matriz, 4);
		printf("¿Hacia donde quieres mover?(w/a/s/d): ");
		cin >> movimiento;
		switch (movimiento)
		{
		case 'w':
		case 'a':
		case 's':
		case 'd':

		default:
			break;
		}
		system("CLS");
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