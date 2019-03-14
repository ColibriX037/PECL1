#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <time.h>
#include <stdlib.h>
#include <stdio.h>
#include <iostream>
#include <fstream>
#include <windows.h>


using namespace std;

void showMatriz(int *matriz, int anchura, int altura);
void generateSeeds(int *matriz, int ancho, int alto, int cantidad, char modo);
void gestionSemillas(int *matriz, int ancho, int numeroSemillas, int alto, char modo);
int checkFull(int *matriz, int tamano);
bool checkMove(int *matriz, int ancho, int alto);
void guardar(int vidas, int *tablero, int altura, int anchura, char dificultad);
int* cargar();

cudaError_t cudaStatus;

__global__ void mov_upK(int *matriz, int anchura, int altura) {

}


cudaError_t move_up(int *matriz, int ancho, int alto) {
	cudaError_t cudaStatus;

	return cudaStatus;
}

__global__ void mov_downK(int *matriz, int anchura, int altura) {

}

cudaError_t move_down(int *matriz, int ancho, int alto) {
	cudaError_t cudaStatus;

	return cudaStatus;
}

__device__ void add_left(int *matriz, int x, int y, int altura, int anchura)
{
	if (y != 0 && y < anchura)
	{
		//printf("Soy el hilo alturaa %d id %d valor %d\n", x, y, matriz[x*anchura + y]);
		if (matriz[x*anchura + y] != 0)
		{
			//printf("Soy el hilo alturaa %d id %d valor %d distinto de cero\n", x, y, matriz[x*anchura + y]);
			if (matriz[x*anchura + y] == matriz[x*anchura + (y - 1)])
			{
				//printf("Soy el hilo alturaa %d id %d valor %d y mi anterior hilo alturaa %d id %d valor %d es igual que yo\n", x, y, matriz[x*anchura + y], x, y - 1, matriz[x*anchura + (y - 1)]);
				int iguales = 0;
				iguales++;
				for (int i = 1; i <= y; i++)
				{
					if (matriz[x*anchura + y] == matriz[x*anchura + (y - i)])
					{
						iguales++;
					}
					else {
						break;
					}
				}
				if (iguales % 2 == 0)
				{
					matriz[x*anchura + (y - 1)] = matriz[x*anchura + (y - 1)] * 2;
					matriz[x*anchura + y] = 0;
				}
			}
			else if (matriz[x*anchura + (y - 1)] == 0)
			{
				matriz[x*anchura + (y - 1)] = matriz[x*anchura + y];
				matriz[x*anchura + y] = 0;
			}
		}
	}
}

__device__ void stack_left(int *matriz, int anchura, int altura, int x, int y) {

	if (x != 0)
	{
		for (int i = x; i > 0; i--)
		{
			if (matriz[x*anchura + (y - 1)] == 0)
			{
				matriz[x*anchura + (y - 1)] = matriz[x*anchura + y];
				matriz[x*anchura + y] = 0;
			}
			__syncthreads();
		}
	}

}

__global__ void mov_leftK(int *matriz, int anchura, int altura) {
	int x = threadIdx.x;
	int y = threadIdx.y;

	stack_left(matriz, anchura, altura, x, y);
	add_left(matriz, x, y, altura, anchura);
	stack_left(matriz, anchura, altura, x, y);
}

cudaError_t move_left(int *matriz, int ancho, int alto) {
	cudaError_t cudaStatus;

	return cudaStatus;
}

__global__ void mov_rightK(int *matriz, int anchura, int altura) {

}



cudaError_t move_right(int *matriz, int ancho, int alto) {
	cudaError_t cudaStatus;

	return cudaStatus;
}


int main()
{
	cudaError_t cudaStatus;
	srand(time(NULL));

	int ancho;
	int alto;
	int numSemillas = 0;
	int vidas = 5;
	char modo;
	char cargado;
	char ia;
	int *datos;
	int *matriz;

	printf("Desea activar la IA? (y/n)");
	cin >> ia;

	printf("Desea comprobar si hay partidas guardadas?(y/n): ");
	cin >> cargado;
	if (cargado == 'y')
	{
		datos = cargar();

		vidas = datos[0];
		alto = datos[1];
		ancho = datos[2];

		int dificultad = datos[3];

		if (dificultad == 0)
		{
			modo = 'B';
			numSemillas = 15;
		}
		else
		{
			modo = 'A';
			numSemillas = 8;
		}

		matriz = (int*)malloc(ancho*alto * sizeof(int));

		for (int i = 0; i < alto*ancho; i++)
		{
			matriz[i] = datos[4 + i];
		}
	}
	else
	{
		printf("Indique el ancho de la matriz: ");
		cin >> ancho;
		printf("Indique el alto de la matriz: ");
		cin >> alto;
		printf("Indique la dificultad del juego (B->Bajo / A->Alto): ");
		cin >> modo;
		switch (modo)
		{
		case 'B':
			numSemillas = 15;
			break;
		case 'A':
			numSemillas = 8;
			break;
		default:
			break;
		}



		matriz = (int*)malloc(ancho*alto * sizeof(int));
		for (int i = 0; i < ancho*alto; i++) {
			matriz[i] = 0;
		}
	}

	if (ia == 'n')
	{
		while ((!checkFull(matriz, ancho*alto) || checkMove(matriz, ancho, alto)) && vidas > 0)
		{
			system("CLS");



			if (!(!checkFull(matriz, ancho*alto) || checkMove(matriz, ancho, alto)) && vidas > 0)
			{
				for (int i = 0; i < ancho*alto; i++) {
					matriz[i] = 0;
				}
				vidas--;
			}




			gestionSemillas(matriz, ancho, numSemillas, alto, modo);

			printf("checkMove: %d\n", checkMove(matriz, ancho, alto));
			printf("checkFull: %d\n", checkFull(matriz, ancho*alto));

			char movimiento = 'p';
			printf("Vidas restantes: %d\n", vidas);
			printf("Tablero:\n");
			showMatriz(matriz, ancho, alto);
			printf("Hacia donde quieres mover?(w/a/s/d) Para guardar teclee g: ");
			cin >> movimiento;
			switch (movimiento)
			{
			case 'w':
				cudaStatus = move_up(matriz, ancho, alto);
				break;
			case 'a':
				cudaStatus = move_left(matriz, ancho, alto);
				break;
			case 's':
				cudaStatus = move_down(matriz, ancho, alto);
				break;
			case 'd':
				cudaStatus = move_right(matriz, ancho, alto);
				break;
			case 'g':
				guardar(vidas, matriz, alto, ancho, modo);
				printf("Partida guardada, hasta pronto!");
				return 0;
			default:
				break;
			}


			if (!(!checkFull(matriz, ancho*alto) || checkMove(matriz, ancho, alto)) && vidas > 0)
			{
				for (int i = 0; i < ancho*alto; i++) {
					matriz[i] = 0;
				}
				vidas--;
			}

		}



		cudaStatus = cudaDeviceReset();
		if (cudaStatus != cudaSuccess) {
			fprintf(stderr, "cudaDeviceReset failed!");
			return 1;
		}
	}
	else {

		while ((!checkFull(matriz, ancho*alto) || checkMove(matriz, ancho, alto)) && vidas > 0)
		{
			if (!(!checkFull(matriz, ancho*alto) || checkMove(matriz, ancho, alto)) && vidas > 0)
			{
				for (int i = 0; i < ancho*alto; i++) {
					matriz[i] = 0;
				}
				vidas--;
			}


			system("CLS");

			gestionSemillas(matriz, ancho, numSemillas, alto, modo);

			printf("checkMove: %d\n", checkMove(matriz, ancho, alto));
			printf("checkFull: %d\n", checkFull(matriz, ancho*alto));

			char movimiento = 'p';
			printf("Vidas restantes: %d\n", vidas);
			printf("Tablero:\n");
			showMatriz(matriz, ancho, alto);

			int r = rand() % 4;

			switch (r)
			{
			case 0:
				printf("Moviendo hacia arriba\n");
				cudaStatus = move_up(matriz, ancho, alto);
				if (cudaStatus != cudaSuccess) {
					fprintf(stderr, "cudaDeviceReset failed!");
					return 1;
				}
				break;
			case 1:
				printf("Moviendo hacia izquierda\n");
				cudaStatus = move_left(matriz, ancho, alto);
				if (cudaStatus != cudaSuccess) {
					fprintf(stderr, "cudaDeviceReset failed!");
					return 1;
				}
				break;
			case 2:
				printf("Moviendo hacia abajo\n");
				cudaStatus = move_down(matriz, ancho, alto);
				if (cudaStatus != cudaSuccess) {
					fprintf(stderr, "cudaDeviceReset failed!");
					return 1;
				}
				break;
			case 3:
				printf("Moviendo hacia derecha\n");
				cudaStatus = move_right(matriz, ancho, alto);
				if (cudaStatus != cudaSuccess) {
					fprintf(stderr, "cudaDeviceReset failed!");
					return 1;
				}
				break;
			default:
				break;
			}


			if (!(!checkFull(matriz, ancho*alto) || checkMove(matriz, ancho, alto)) && vidas > 0)
			{
				for (int i = 0; i < ancho*alto; i++) {
					matriz[i] = 0;
				}
				vidas--;
			}

		}



		cudaStatus = cudaDeviceReset();
		if (cudaStatus != cudaSuccess) {
			fprintf(stderr, "cudaDeviceReset failed!");
			return 1;
		}
	}


	return 0;
}

// Metodo que SOLO muestra matrices cuadradas
void showMatriz(int *matriz, int anchura, int altura)
{
	for (int i = 0; i < altura; i++)
	{
		for (int j = 0; j < anchura; j++)
		{
			printf("%d\t", matriz[i*anchura + j]);
		}
		printf("\n");
	}
}

void generateSeeds(int *matriz, int ancho, int alto, int cantidad, char modo)
{
	int total = ancho * alto;
	int num;

	if (modo == 'B')
	{

		for (int i = 0; i < cantidad; i++)
		{
			int r = rand() % total;
			while (matriz[r] != 0) {
				r = rand() % total;
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
	else if (modo == 'A')
	{
		for (int i = 0; i < cantidad; i++)
		{
			int r = rand() % total;
			while (matriz[r] != 0) {
				r = rand() % total;
			}

			int opcion = rand() % 100;
			if (opcion <= 60) {
				matriz[r] = 2;
			}
			else {
				matriz[r] = 4;
			}

		}
	}



}

bool checkMove(int *matriz, int anchura, int altura)
{
	for (int i = 0; i < anchura*(altura - 1); i++)
	{
		if (matriz[i] == matriz[i + anchura] || matriz[i + anchura] == 0)
		{
			return true;
		}
	}

	for (int i = anchura; i < anchura*altura; i++)
	{
		if (matriz[i] == matriz[i - anchura] || matriz[i - anchura] == 0)
		{
			return true;
		}
	}

	for (int i = 0; i < altura; i++)
	{
		for (int j = 0; j < anchura - 1; j++)
		{
			if (matriz[i*anchura + i] == matriz[i*anchura + i + 1] || matriz[i*anchura + i + 1] == 0)
			{
				return true;
			}
		}
	}

	for (int i = 0; i < altura; i++)
	{
		for (int j = 1; j < anchura; j++)
		{
			if (matriz[i*anchura + i] == matriz[i*anchura + i - 1] || matriz[i*anchura + i - 1] == 0)
			{
				return true;
			}
		}
	}

	return false;

}

int checkFull(int *matriz, int tamano)
{
	int flag = 1;
	for (int i = 0; i < tamano; i++)
	{
		if (matriz[i] == 0)
		{
			flag = 0;
		}
	}
	return flag;
}

void gestionSemillas(int *matriz, int ancho, int numeroSemillas, int alto, char modo)
{
	if (!checkFull(matriz, ancho*alto))
	{
		int n = 0;
		for (int i = 0; i < ancho*alto; i++)
		{
			if (matriz[i] == 0)
				n++;
		}
		if (modo == 'B')
		{
			if (n < 15)
			{
				generateSeeds(matriz, ancho, alto, n, modo);
			}
			else {
				generateSeeds(matriz, ancho, alto, numeroSemillas, modo);
			}

		}

	}
}

void guardar(int vidas, int *matriz, int altura, int anchura, char dificultad) {

	ofstream archivo;
	int dif;

	archivo.open("2048_savedata.txt", ios::out); //Creamos o reemplazamos el archivo

	//Si no se puede guardar ERROR
	if (archivo.fail())
	{
		cout << "Error al guardar la partida.\n";
		exit(1);
	}

	if (dificultad == 'B')
	{
		dif = 0;
	}
	else
	{
		dif = 1;
	}

	archivo << vidas << endl; //Guardamos las vidas
	archivo << altura << endl; //Guardamos las altura
	archivo << anchura << endl; //Guardamos las anchura
	archivo << dif << endl; //Guardamos la dificultad

	//Guardamos la matriz
	for (int i = 0; i < (altura*anchura); i++)
	{
		archivo << matriz[i] << " ";
	}
	cout << "\nPartida guardada con exito." << endl;

	archivo.close(); //Cerramos el archivo
}

int* cargar() {

	ifstream archivo;
	int i = 4, vidas, altura, anchura, dif;
	int *partida;

	archivo.open("2048_savedata.txt", ios::in); //Abrimos el archivo en modo lectura

	//Si no se puede cargar ERROR
	if (archivo.fail())
	{
		cout << "Error al abrir la partida guardada. El fichero no existe o está corrupto\n";
		exit(1);
	}

	archivo >> vidas;
	archivo >> altura;
	archivo >> anchura;
	archivo >> dif;

	partida = (int*)malloc(4 * sizeof(int) + altura * anchura * sizeof(int)); //Reservamos memoria para los datos de la partida

	partida[0] = vidas; //Guardamos vidas
	partida[1] = altura; //Guardamos altura
	partida[2] = anchura; //Guardamos anchura
	partida[3] = dif; //Guardamos la dificultad

	//Guardamos la matriz
	while (!archivo.eof()) { //Mientras no sea el final del archivo
		archivo >> partida[i];
		i++;
	}

	archivo.close(); //Cerramos el archivo

	return partida;
}