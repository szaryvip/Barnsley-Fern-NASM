#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <stdint.h>
#include <allegro5/allegro.h>
#include <allegro5/allegro_image.h>
#include <allegro5/allegro_primitives.h>
#include <allegro5/allegro_native_dialog.h>
#include "generate_fern.h"

#pragma pack(1)

/*
 * important constants
 */
#define OUTPUT_FILE_NAME "output.bmp"

/*
 * Constants for .bmp file such as pixel offset
 * we use basic windows's standard DIB header
 * its size is 14 bytes + 40 bytes = 54 bytes
 */
#define BMP_HEADER_SIZE 54
#define BMP_PIXEL_OFFSET 54
#define BMP_PLANES 1
#define BMP_BPP 24
#define BMP_HORIZONTAL_RES 1024
#define BMP_VERTICAL_RES 1024
#define BMP_DIB_HEADER_SIZE 40 //windows header

/*
 * struct for bmp header.
 */
typedef struct {
    unsigned char sig_0;
    unsigned char sig_1;
    uint32_t size;
    uint32_t reserved;
    uint32_t pixel_offset;
    uint32_t header_size;
    uint32_t width;
    uint32_t height;
    uint16_t planes;
    uint16_t bpp_type;
    uint32_t compression;
    uint32_t image_size;
    uint32_t horizontal_res;
    uint32_t vertical_res;
    uint32_t color_palette;
    uint32_t important_colors;
} BmpHeader;

/*
 * Initializes bmp_header with default values
 */
void init_bmp_header(BmpHeader *header)
{
    header -> sig_0 = 'B';
    header -> sig_1 = 'M';
    header -> reserved = 0;
    header -> pixel_offset = BMP_PIXEL_OFFSET;
    header -> header_size = BMP_DIB_HEADER_SIZE;
    header -> planes = BMP_PLANES;
    header -> bpp_type = BMP_BPP;
    header -> compression = 0;
    header -> image_size = 0;
    header -> horizontal_res = BMP_HORIZONTAL_RES;
    header -> vertical_res = BMP_VERTICAL_RES;
    header -> color_palette = 0;
    header -> important_colors = 0;
}

/*
 * writes bmp buffer array into .bmp file
 */
void write_bytes_to_bmp(unsigned  char *buffer, size_t size)
{
    FILE *file;

    file = fopen(OUTPUT_FILE_NAME, "wb");
    if (file == NULL)
    {
        printf("Could not open output file. Exiting!");
        exit(-1);
    }
    fwrite(buffer, 1, size, file);
    fclose(file);
}

/*
 * Generate empty bitmap for assembler usage. Initialize with white pixels
 */
unsigned char *generate_empty_bitmap(unsigned int width, unsigned int height, size_t *output_size)
{
    unsigned int row_size = (width*3 + 3) & ~3; //najmnniejsza wielokrotnosc 4
    *output_size = row_size * height + BMP_HEADER_SIZE;
    unsigned char *bitmap = (unsigned char *) malloc(*output_size);

    BmpHeader header;
    init_bmp_header(&header);
    header.size = *output_size;
    header.width = width;
    header.height = height;

    memcpy(bitmap, &header, BMP_HEADER_SIZE);
    for(int i = BMP_HEADER_SIZE; i < *output_size; ++i)
    {
        bitmap[i] = 0xff;
    }
    return bitmap;
}

/*
 * Ask for parameters
 */
void input_parameters(int *counter, int *f1, int *f2, int *f3)
{
    bool wrong = true;
    while(wrong)
    {
        printf("Step counter (suggested: 1000000): ");
        scanf("%d", counter);
        printf("F1 probability (suggested: 85 - 85 means 85%%): ");
        scanf("%d", f1);
        printf("F2 probability (suggested: 7): ");
        scanf("%d", f2);
        printf("F3 probability (suggested: 7): ");
        scanf("%d", f3);
        *f2 += *f1;
        *f3 += *f2;
        if (*f3 <= 100)
            wrong = false;
        else
            printf("Incorrect values of probabilities!\nThey have to sum up max to 100. Try again!\n");
    }
    
}

volatile bool close_button = false;

void close_button_handler()
{
	close_button = true;
}

void check_if_close(ALLEGRO_EVENT_QUEUE* queue, ALLEGRO_EVENT* event)
{
    al_wait_for_event(queue, event);
    if((*event).type == ALLEGRO_EVENT_DISPLAY_CLOSE)
        close_button_handler();   
}

int main()
{
    
    size_t bmp_size = 0;
    
    ALLEGRO_BITMAP *allegro_bitmap = NULL;
    ALLEGRO_DISPLAY  *display = NULL;
    al_init(); //initialising the library
	al_init_image_addon(); //init allegro to image operations
    al_init_primitives_addon();
    ALLEGRO_EVENT_QUEUE *event_queue = al_create_event_queue();
    display = al_create_display(BMP_HORIZONTAL_RES, BMP_VERTICAL_RES); //creating a window, 
    al_register_event_source(event_queue, al_get_display_event_source(display));
   
    int f1_prob = 85;
    int f2_prob = f1_prob + 7;
    int f3_prob = f2_prob + 7;
    int counter = 1000000;

    while(!close_button)
    {
        unsigned char *bmp_buffer = generate_empty_bitmap(BMP_HORIZONTAL_RES, BMP_VERTICAL_RES, &bmp_size);
        ALLEGRO_EVENT events;
        al_wait_for_event(event_queue, &events);

        if(events.type == ALLEGRO_EVENT_DISPLAY_CLOSE)
        {
            close_button_handler();
            break;
        }
            
        input_parameters(&counter, &f1_prob, &f2_prob, &f3_prob);

        check_if_close(event_queue, &events);

        generate_fern(counter, bmp_buffer, f1_prob, f2_prob, f3_prob);//call nasm function
        
        write_bytes_to_bmp(bmp_buffer, bmp_size);//save bmp buffer into file
        
        allegro_bitmap = al_load_bitmap(OUTPUT_FILE_NAME); 
        al_draw_bitmap(allegro_bitmap , 0 , 0 , 0); //draw bitmap on display
        al_flip_display();  //displaying the window (the buffer)
        free(bmp_buffer); //deallocate bmp buffer
    }

	al_destroy_display(display); //destroying the window
	al_destroy_bitmap(allegro_bitmap); //destroying allegro bitmap
    
    return 0;
}

