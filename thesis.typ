#set page(
  paper: "a4",
  margin: (top: 20mm, bottom: 20mm, left: 30mm, right: 15mm),
)

#set text(
font: "Times New Roman",
size: 14pt,
spacing: 300%,
)

#set par(
  first-line-indent: (amount: 1.25cm, all: true),
  justify: true,
  spacing: 1.25cm,
  leading: 1em,
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

#show raw.where(block: true): block.with(
  fill: luma(240),
  inset: 10pt,
  radius: 4pt,
)

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
  [CAS - Compare And Swap],
  [MWCAS - Multi Word Compare And Swap],
  [ОС -  Операционная Система],
  [MVCC - Multi Version Concurrency Control]
)

#pagebreak()

#HeaderBlank("Введение",1)
На сегодняшний день в основе большинства разрабатываемых приложений: веб-серверов, кластеров обработки данных и.т.п. лежит инфрастуктурная основа в виде надёжной и производительной среды предоставления асинхронного исполнения - runtime. От него требуется обеспечение эффективной обработки задач, предоставления инструментов композиции и коммуникации между ними. Такая основа может быть встроена в сам язык, как например в Elixir и Go, или использоваться как отдельная библиотека. Примером такого подхода являются библиотеки Kotlin Coroutines и Rust Tokio.

Любой такой инструмент строит свои абстракции исполнения поверх процессов или потоков, предоставляемых операционной системой. Поэтому неминуемо возникает потребность в синхронизации между ними. Синхронизация по своей природе может быть нескольких типов. Каждый из них предоставлет как преимущества, так и недостатки.
Современные архитектуры имеют тенденцию распараллеливать вычислетельные процессы. Однако в большом числе случаев для синхронизации до сих пор используются инструменты крайне неэффектино масштабирующиеся вслед за архитектурой ЭВМ. В большинстве случаев - это блокирующая синхронизация, несмотря на то, что существуют способы производить операции в неблокирующем режиме, который открывает возможности к существенному масштабированию вычислений. Связано это с тем, что неблокиющая синхронизация довольно сложна в реализации, в отличие от блокирующей, а для комплексных структур данных эффективная реализация становится практически невозможной.

В рамках данной работы рассмотрена возможная оптимизация для примитивов синхронизации фреймворка Tokio в среде языка Rust.

#pagebreak()

#HeaderBlank("Цели и задачи работы",1)

Целью работы является оптимизация модуля широковещательной рассылки фреймворка Tokio.

Для выполнения цели были выделены следующие задачи:

- Определить оптимальный дизайн очереди
- Реализовать полученную модель
- Провести сравнительное тестирование


#HeaderBlank("Введение в предметную область",1)

#HeaderNumbered("Синхронизация", 2)

Синхронизация между потоками по своей природе может быть разных видов, в понимании того, что они предоставляют пользователю разные гарантии прогресса многопоточного исполнения. Каждый вид на сегодняшний день имеет как свои достоинтсва, так и недостатки.

#HeaderNumbered("Блокирующая синхронизация", 3)

Первый тип представляет собой блокирование прогресса всех исполняемых задач на время выполнения одной или нескольких выбранных задач. У такого типа синхронизации есть большое преимущество - он простой и не требует специального подхода к построению структуры данных над которой производятся операции.

Самый простой пример такой синхронизации - использование мьютекса:


```rust
// Располагается в общей для потоков памяти
let mutex = Mutex::<State>

fn doCriticalSection(){
	{
	mutex.lock()
    // Критическая секция
    mutex.unlock()
	}
}
```


Однако данный подход крайне неэффективно масштабируется, ведь в единицу времени может выполняться только одна критическая секция. Остальные потокам необходимо ждать освобожнение блокировки. Ожидание может быть сопряжено с дополнительными системными вызовами, например futex syscall. Или же затраты на переключение контекста и координацию в очередях ожидиания, в случае использования корутин поверх потоков.

Если присутствует большое число потоков оперирующих над критической секцией, появляется большое число накладных расходов, накладных расходов. В  худшем случае такое исполнение может показать производительность сравнительно худшую чем обычное последовательное исполнение. Существует также проблема, при которой поток или процесс захвативший блокировку и исполняющий критическую секцию, будет временно снят с исполнения планировщиком задач операционной системы. В данном случае возникает риск полной остановки прогресса исполнения системы до разблокировки.

#pagebreak()

#HeaderNumbered("Неблокирующая синхронизация", 3)

Для избавления от проблем присущих блокирующей синхронизации, существует альтернативный подход, при котором, операции над данными осуществляются в "неблокирующем режиме".

Неблокирующая синхронизация предоставляет следующие преимущества по сравнению с блокирующей:

- Гарантия прогресса системы в целом - означает, что при любом исполнении, всегда есть поток или потоки успешно завершающие свои операции. Решения планировщика ОС теперь не могут привести к полной остановке системы.
- Более высокая масштабируемость - при использовании неблокирующей синхронизации потоки не обязаны ждать друг друга, поэтому операции могут работать в параллель. Вся координация между потоками образуется в специальных точках синхронизации. В большинстве языков программирования - это атомарные переменные.
- Меньшие накладные расходы на синхронизацию. Использование атомарных переменных не требует обращения к ядру операционной системы. Операции над атомарными переменными напрямую синхронизирут L2 кэш ядер процессора, за счёт чего достигается синхронизация памяти ядер.

#pagebreak()

#HeaderNumbered("Общий подход к неблокирущей синхронизации", 3)

При использовании неблокирующей синхронизации образуется общий подход при построении структуры даннных и операций над ней.
Выделяется общее состоянии, которое становится атомарной ячейкой памяти, в том плане, что все операции над ней линеаризуемы и образуют некоторый порядок обращений.

Все операции абстрактно разбиваются на три этапа:
1. Копирование текущего состояния (snapshot).
2. Локальная модификация полученного состояния.
3. Попытка замена общего состояния на модифицированную копию, в случае, если общее состояние за время модификации не изменилось. Если состояние успело измениться - начать заного с шага №1.

На такое поведение можно смотреть как на транзакцию над одной ячейкой памяти.

Абстрактно это можно представить так:
```rust
// Располагается в общей для потоков памяти
let state = Atomic<State>

fn doLockFreeOperation(){
while(true){
	let old_state = state.atomic_read()
	let modified_state = modify(old_state)
	if(state.atomic_cas(old_state,modified_state)){
		break;
	} else{
		 // Операция по замене неуспешна
		 // Поток повторяет цикл
		continue;
	}
}
}
```

Несмотря на свои плюсы, такой подход обладает одним серъездным недостатком. Необходимая линеаризуемость и следующая из неё синхронизация, образуется лишь вокруг одной ячейки памяти. Однако в большинстве структур данных чаще всего требуется атомарная замена сразу нескольких ячеек памяти. Для решения такой проблемы была представлена транзакционная память. Её можно реализовать как на уровне процессора, так и программно. Так как сейчас процессоры не поддерживают подобную опцию, будет рассмотрено использование программной реализация в виде примитива MWCAS.

#HeaderNumbered("Обзор MWCAS", 2)

MWCAS обобщает подход транзакции над одной ячейкой памяти до произвольного их числа.


Пример исполнения транзакции может выглядеть следующим образом:
```rust
// Ячейки располагаются в общей для потоков памяти
let state_1 = Atomic<State>
let state_2 = Atomic<State>

fn doAtomicTransaction(){
while(true){
	let old_state1 = state_1.atomic_read()
	let old_state2 = state_2.atomic_read()

	let modified_state_1 = modify(old_state_1)
	let modified_state_2 = modify(old_state_2)

	let mwcas = new Mwcas

	// Транзакция атомарно заменяет ожидаемые значения
    // на модифицированные  копии.
    // В случае, если наблюдаемое старое значение изменилось
    // Транзакция помогает завершиться другой возможной транзакции
    // и сообщает о неуспешном завершении
	if(mwcas.transaction(
	memory_cell = [state_1, state_2]
	expected_states = [old_state1, old_state2],
	new_states = [modified_state_1, modified_state_2],
	)){
		break;
	} else{
		 // Транзакция прошла неуспешно
		 // Поток повторяет цикл
		continue;
	}
}
}
```







#pagebreak()

#HeaderBlank("Обзор модуля широковещательной рассылки Tokio",1)

#HeaderNumbered("Архитектура",2)


#HeaderBlank("Основная часть",1)

- обзор mcas + pseudo
- Обзор tokio + pseudo текущей
- mcas tokio + pseudo
- аллокации в mcas возможные ускорения и реализации
- benches текущие и реализованные + картинки большие)

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
