#set page(
  paper: "a4",
  margin: (top: 20mm, bottom: 20mm, left: 30mm, right: 15mm),
)

#set text(
font: "Times New Roman",
size: 14pt,
spacing: 150%,
)

#set par(
  justify: true,
  spacing: 1.25cm,
)

#let CenteredHeader(text, depth) = {
  align(center)[
    #heading(depth: depth)[
      #text
    ]
  ]
  v(1em) // Aditional spacing after header
}

#let Image(path,num, width, caption) = {
  figure(
    image(path, width: width),
    caption: [
      Рисунок #num. #caption
    ],
    supplement: none
  )
}

#let start_page_num = 2

#pagebreak()

// Setup numbering starting from this page with 2
#set page(numbering: "1")
#counter(page).update(start_page_num)
// Could not center title, so made it separate
#CenteredHeader("Содержание",1)
#outline(title: "")

#pagebreak()

#CenteredHeader("Список сокращений и условных обозначений",1)
#list(
  spacing: 7mm,
  [Термин1 - ],
  [Термин2 - ],
  [... - ],
)

#pagebreak()

#CenteredHeader("Введение",1)
#lorem(30)

#lorem(10)

#pagebreak()

#CenteredHeader("Основная часть",1)
#lorem(30)
#Image("image/cat_sample.jpeg", 1, 80%, "Пример Изображения")

#CenteredHeader("Актуальность темы исследования", 2)
#lorem(30)

#CenteredHeader("Цель и Задачи", 2)
#lorem(30)

#pagebreak()

#CenteredHeader("Заключение",1)
#lorem(30)
#table(
  columns: (auto, auto, auto),
  inset: 10pt,
  align: horizon,
  table.header(
    [*Таблица*], [*для*], [*примера*],
  ),
  "item1",
  $ sum_(k=0)^n k &= 1 + ... + n $,
  "description1",

  "item2",
  $ sqrt(2) $,
  "description2"
)

#pagebreak()

#CenteredHeader("Список использованных источников",1)
#lorem(30)

#pagebreak()

#CenteredHeader("Приложение",1)
#lorem(30)
