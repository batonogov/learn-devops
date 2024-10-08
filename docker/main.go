package main

import (
	"fmt"
	"net/http"
	"os"
)

func main() {
	// Обработчик запросов
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		// Получаем имя хоста
		hostname, err := os.Hostname()
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		// Отправляем имя хоста в ответ
		fmt.Fprintf(w, "Имя узла: %s\n", hostname)
	})

	// Запуск веб-сервера на порту 8080
	fmt.Println("Сервер запущен на порту 8080...")
	if err := http.ListenAndServe(":8080", nil); err != nil {
		fmt.Printf("Ошибка запуска сервера: %s\n", err)
	}
}
