#include "SDL2/SDL.h"

void main() {
  SDL_Init(62001);
  SDL_Window* window =
      SDL_CreateWindow("Hello", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
                       200, 200, SDL_WINDOW_SHOWN | SDL_WINDOW_RESIZABLE);
  SDL_Renderer* renderer =
      SDL_CreateRenderer(window, -1, 0);  // SDL_RENDERER_ACCELERATED
  SDL_Texture* texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_ARGB8888,
                                           SDL_TEXTUREACCESS_TARGET, 8, 8);

  while (1) {
    printf("looping\n");
    SDL_Event* event;
    if (SDL_PollEvent(event)) if (event->type == SDL_QUIT) break;

    SDL_SetRenderTarget(renderer, texture);

    SDL_SetRenderDrawColor(renderer, 255, 0, 0, 255);
    SDL_RenderClear(renderer);
    SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
    SDL_RenderDrawPoint(renderer, 1, 1);

    SDL_SetRenderTarget(renderer, NULL);
    SDL_RenderCopy(renderer, texture, NULL, NULL);
    SDL_RenderPresent(renderer);
    SDL_Delay(20);
  }
}
