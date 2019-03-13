#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <time.h>
#include <stdlib.h>
#include <stdio.h>
#include <iostream>
#include <fstream>

using namespace std;

void showMatriz(int matriz[], int anchura, int altura);
void generateSeeds(int matriz[],int ancho, int alto ,int cantidad,char modo);
void gestionSemillas(int *matriz, int ancho,int numeroSemillas, int alto, char modo);
bool checkFull(int matriz[], int tamano);
bool checkMove(int matriz[], int ancho, int alto);
void guardar(int vidas, int *tablero, int altura, int anchura, char dificultad);
int* cargar();

cudaError_t cudaStatus;
bool partida_enCurso = true;

__global__ void mov_upK(int *matriz, int anchura, int altura) {

	int x = threadIdx.x;

	int *vector = (int*)malloc(sizeof(int)*altura);
	for (int i = 0; i < altura; i++)
	{
		vector[i] = 0;
	}

	int *aux = (int*)malloc(sizeof(int)*altura);
	for (int i = 0; i < altura; i++)
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

	int *vector = (int*)malloc(sizeof(int)*altura);
	for (int i = 0; i < altura; i++)
	{
		vector[i] = 0;
	}

	int *aux = (int*)malloc(sizeof(int)*altura);
	for (int i = 0; i < altura; i++)
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

__global__ void mov_leftK(int *matriz, int anchura, int altura) {

	int x = threadIdx.x;

	int *vector = (int*)malloc(sizeof(int)*anchura);
	for (int i = 0; i < anchura; i++)
	{
		vector[i] = 0;
	}

	int *aux = (int*)malloc(sizeof(int)*anchura);
	for (int i = 0; i < anchura; i++)
	{
		aux[i] = 0;
	}


	int posicion_Vector = 0;
	for (int i = 0; i < anchura; i++)
	{
		if (matriz[x*anchura + i] != 0) {
			vector[posicion_Vector] = matriz[x*anchura + i];
			posicion_Vector++;
		}
	}

	int posicion_aux = 0;
	for (int j = 0; j < anchura; j++)
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

	for (int k = 0; k < anchura; k++)
	{
		if (!aux[k])
		{
			aux[k] = 0;
		}
	}

	for (int i = 0; i < anchura; i++)
	{
		matriz[x*anchura + i] = aux[i];
	}
}

cudaError_t move_left(int *matriz, int ancho, int alto) {
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

	mov_leftK << < 1, ancho >> > (dev_m, ancho, alto);

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

__global__ void mov_rightK(int *matriz, int anchura, int altura) {

	int x = threadIdx.x;

	int *vector = (int*)malloc(sizeof(int)*anchura);
	for (int i = 0; i < anchura; i++)
	{
		vector[i] = 0;
	}

	int *aux = (int*)malloc(sizeof(int)*anchura);
	for (int i = 0; i < anchura; i++)
	{
		aux[i] = 0;
	}


	int posicion_Vector = 0;
	for (int i = anchura-1; i >=0; i--)
	{
		if (matriz[x*anchura + i] != 0) {
			vector[posicion_Vector] = matriz[x*anchura + i];
			posicion_Vector++;
		}
	}

	int posicion_aux = 0;
	for (int j = 0; j < anchura; j++)
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

	for (int k = 0; k < anchura; k++)
	{
		if (!aux[k])
		{
			aux[k] = 0;
		}
	}

	for (int i = 0; i < anchura; i++)
	{
		matriz[(x*anchura) + (anchura-1-i)] = aux[i];
	}
}

cudaError_t move_right(int *matriz, int ancho, int alto) {
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

	mov_rightK << < 1, ancho >> > (dev_m, ancho, alto);

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
	int *datos;
	int *matriz;

	printf("Desea comprobar si hay partidas guardadas?(y/n): ");
	cin >> cargado;
	if (cargado == 'y') 
	{
		datos = cargar();

		vidas = datos[0];
		alto = datos[1];
		ancho = datos[2];

		int dificultad = datos[3];

		if(dificultad == 0)
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
	

	while (!checkFull(matriz,ancho*alto) || checkMove(matriz,ancho,alto)) 
	{
		system("CLS");

		gestionSemillas(matriz, ancho,numSemillas, alto, modo);

		char movimiento = 'p';
		printf("Vidas restantes: %d\n", vidas);
		printf("Tablero:\n");
		showMatriz(matriz, ancho,alto);
		printf("Hacia donde quieres mover?(w/a/s/d) Para guardar teclee g: ");
		cin >> movimiento;
		switch (movimiento)
		{
		case 'w':
			cudaStatus = move_up(matriz,ancho,alto);
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
			guardar(vidas,matriz,alto,ancho,modo);
			printf("Partida guardada, hasta pronto!");
			return 0;
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
	
    return 0;
}

// Metodo que SOLO muestra matrices cuadradas
void showMatriz(int matriz[], int anchura , int altura)
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

void generateSeeds(int matriz[], int ancho, int alto,int cantidad, char modo)
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

bool checkMove(int matriz[], int ancho, int alto)
{
    int contador = 0;
    int paso = 0;
    for (int i = 0; i < alto-1; i++)
    {
        for ( int j = 0; j < ancho - 1; j++)
        {
            if (matriz[paso] == matriz[paso + ancho] && matriz[paso + ancho]==0)
                return true;
            if (matriz[paso] == matriz[paso + 1] && matriz[paso + 1] == 0)
                return true;
            paso++;
        }
        paso = paso + 2;

    }

    paso = paso + ancho-1;

    for (int k = 0; k < alto - 1; k++) 
    {
        if (matriz[paso] == matriz[paso + ancho] && matriz[paso + ancho] == 0)
            return true;
    }

    paso = ancho*alto-2;

    for (int l = 0; l < ancho-2; l++) 
    {
        if (matriz[paso] == matriz[paso + 1] && matriz[paso + ancho] == 0)
            return true;
        paso--;
    }

	return false;

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

void gestionSemillas(int *matriz, int ancho,int numeroSemillas, int alto, char modo)
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

	partida = (int*)malloc(altura * anchura * sizeof(int)); //Reservamos memoria para los datos de la partida

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