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
  first-line-indent: (amount: 1.25cm, all: true),
  justify: true,
  spacing: 1.25cm,
)

// Headers types
#set heading(numbering: "1.1")

#let CenteredHeader(text, depth, numbering, outlined) = {
  align(center)[
    #heading(depth: depth, numbering: numbering, outlined: outlined)[
      #text
    ]
  ]
  v(1em) // Aditional spacing after header
}

#let OutlinedHeader(text, depth, numbering) = {
  CenteredHeader(text, depth, numbering, true)
}

#let NotOutlinedHeader(text, depth) = {
  CenteredHeader(text, depth, none, false)
}

#let HeaderBlank(text, depth) = {
  OutlinedHeader(text, depth, none)
}

#let HeaderNumbered(text, depth) = {
  OutlinedHeader(text, depth - 1, "1.1")
}

// Images
#let Image(path,num, width, caption) = {
  figure(
    image(path, width: width),
    caption: [
      Рисунок #num --- #caption
    ],
    supplement: none
  )
}

// Tables
#show figure.where(kind: table): set figure(supplement: "Таблица")
#show figure.where(kind: table): set figure.caption(position: top, separator: [ --- ])
#show figure.caption.where(kind: table): element => [
  #align(left)[#element]
]

#let start_page_num = 2

///////////////////////////////////START///////////////////////////////////

#pagebreak()

// Setup numbering starting from this page with 2
#set page(numbering: "1")
#counter(page).update(start_page_num)
// Could not center title, so made it separate
#NotOutlinedHeader("Содержание",1)

#outline(title: none)

#pagebreak()

#HeaderBlank("Список сокращений и условных обозначений",1)
#list(
  spacing: 7mm,
  [Термин1 - ],
  [Термин2 - ],
  [... - ],
)

#pagebreak()

#HeaderBlank("Введение",1)
На сегодняшний день в основе большинства разрабатываемых приложений: веб-серверов, кластеров обработки данных и.т.п. лежит инфрастуктурная основа в виде
надёжной и производительной среды предоставления асинхронного исполнения - runtime. От него требуется обеспечение эффективной обработки задач, предоставления инструментов композиции и коммуникации между ними. Такая основа может быть встроена в сам язык, как например в Elixir и Go, или использоваться как отдельная библиотека - Kotlin Coroutines и Rust Tokio.

Любой такой инструмент строит свои абстракции исполнения поверх процессов или потоков, предоставляемых операционной системой. Поэтому неминуемо возникает потребность в синхронизации между ними. Синхронизация по своей природе может быть нескольких типов. Каждый из них предоставлет как преимущества, так и недостатки.
Современные архитектуры имеют тенденцию распараллеливать вычислетельные процессы. Однако в большом числе случаев для синхронизации до сих пор используются инструменты крайне неэффектино масштабирующиеся вслед за архитектурой ЭВМ. В большинстве случаев - это блокирующая синхронизация, несмотря на то, что существуют способы производить операции в неблокирующем режиме, который открывает возможности к существенному масштабированию вычислений. Связано это с тем, что неблокиющая синхронизация довольно сложна в реализации, в отличие от блокирующей, а для комплексных структур данных эффективная реализация становится практически невозможной.

В рамках данной работы рассмотрена возможная оптимизация для примитива широковещательной рассылки, модуля broadcast,j в среде исполнения Tokio для языка Rust.


#pagebreak()

#HeaderBlank("Введение в предметную область",1)

Tokio + broadcast + pseudo ...

Синхронизация по своей природе может быть блокирующей и неблокирующей. Первый тип блокирует прогресс всех исполняемых задач на время выполнения одной или выбранных нескольких задач. У такого типа синхронизации есть большое преимущество - он простой и не требует специального подхода к построения оперируемой структуры данных. Однако данный подход крайне неэффективно масштабируется. В худшем случая оперирование нескольких потоков или процессов в параллель может показать ипсполнение по производительности сравнительно худшее чем последовательное исполнение. Кроме того, существует проблема при которой поток или процесс захвативший блокировку будет временно снят с исполнения планировщиком задач операционной системы. В данном случае возникает полная остановка прогресса исполнения системы.

#pagebreak()

#HeaderBlank("Основная часть",1)
#lorem(30)
(рисунок 1)
#Image("image/cat_sample.jpeg", 1, 80%, "пример изображения")

#HeaderNumbered("Актуальность темы исследования", 2)

#HeaderNumbered("Актуальность темы исследования. Часть 1", 3)
#lorem(30)

#HeaderNumbered("Цель и Задачи", 3)
#lorem(30)

#pagebreak()

#HeaderBlank("Заключение",1)
#lorem(30)

#figure(
table(
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
),
   caption: [Таблица],
)


#pagebreak()

#HeaderBlank("Список использованных источников",1)
#lorem(30)

#pagebreak()

#HeaderBlank("Приложение",1)
#lorem(30)
