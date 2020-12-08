--$Name: Луна-9$
--$Version: 0.1$
--$Author: Пётр Косых$

require "fmt"
fmt.dash = true
fmt.quotes = true
require 'parser/mp-ru'

mp.msg.UNKNOWN_OBJ = function(w)
	if not w then
		p "Об этом предмете ничего не сказано."
	else
		p "Об этом предмете ничего не сказано "
		p ("(",w,").")
	end
end
game.dsc = [[{$fmt b|ЛУНА-9}^^Интерактивная новелла для выполнения на средствах вычислительной техники.^Игра разработана в ОС Plan9 (9front).^^Для помощи, наберите "помощь" и нажмите "ввод".]];

VerbExtend {
	"#Talk",
	"по {noun_obj}/телефон,дт : Ring",
	":Talk"
}

Verb {
	"#Ring",
	"[по|]звон/ить",
	":Ring"
}
function mp.token.ring()
	return "{noun_obj}/телефон,вн|звонок|вызов"
end

Verb {
	"#Answer",
	"ответ/ить,отвеч/ать",
	":Answer",
	"{noun}/дт,live : Answer",
	"на {ring} : Ring"
}


global 'last_talk' (false)

function game:before_Ring(w)
	if not have 'телефон' then
		p [[У тебя нет с собой телефона.]]
		return
	end
	return false
end
function game:after_Ring(w)
	p [[Тебе некому сейчас звонить.]]
end
-- ответить
function game:before_Answer(w)
	if not w then
		if isDaemon 'телефон' then
			mp:xaction("Ring")
			return
		end
		mp:xaction("Talk")
		return
	end
	mp:xaction("Talk", w)
end
-- говорить без указания объекта
function game:before_Talk(w)
	if w then
		last_talk = w
		return false
	end
	if not last_talk or not seen(last_talk) then
		last_talk = false
		for _, v in ipairs(objs()) do
			if v:has'animate' then
				if last_talk then
					last_talk = false
					break
				end
				last_talk = v
			end
		end
		if not last_talk then
			p [[Говорить с кем? Нужно дополнить предложение.]]
			return
		end
	end
	mp:xaction("Talk", last_talk)
	return
end
-- чтобы можно было писать к чему-то -- трансляция в идти.

function mp:pre_input(str)
	local a = std.split(str)
	if #a <= 1 or #a > 3 then
		return str
	end
	if a[1] == 'в' or a[1] == 'на' or a[1] == 'во' or
		a[1] == "к" or a[1] == 'ко' then
		return "идти "..str
	end
	return str
end

function game:before_Any(ev, w)
	if ev == "Ask" or ev == "Say" or ev == "Tell" or ev == "AskFor" or ev == "AskTo" then
		if w then
			p ([[Просто попробуйте поговорить с ]], w:noun'тв', ".")
		else
			p [[Попробуйте просто поговорить.]]
		end
		return
	end
	return false
end
-- класс для переходов
Path = Class {
	['before_Walk,Enter'] = function(s)
		if mp:check_inside(std.ref(s.walk_to)) then
			return
		end
		walk(s.walk_to)
	end;
	before_Default = function(s)
		if s.desc then
			p(s.desc)
			return
		end
		p ([[Ты можешь пойти в ]], std.ref(s.walk_to):noun('вн'), '.');
	end;
	default_Event = 'Walk';
}:attr'scenery,enterable';

Careful = Class {
	before_Default = function(s, ev)
		if ev == "Exam" or ev == "Look" or ev == "Search" or
	ev == 'Listen' or ev == 'Smell' then
			return false
		end
		p ("Лучше оставить ", s:noun 'вн', " в покое.")
	end;
}:attr 'scenery'

Distance = Class {
	before_Default = function(s, ev)
		if ev == "Exam" or ev == "Look" or ev == "Search" then
			return false
		end
		p ("Но ", s:noun(), " очень далеко.");
	end;
}:attr 'scenery'

Ephe = Class {
	description = "Это не предмет.";
	before_Default = function(s, ev)
		if ev == "Exam" or ev == "Look" or ev == "Search" then
			return false
		end
		p ("Но ", s:noun(), " не предмет.");
	end;
}:attr 'scenery'

Furniture = Class {
	['before_Push,Pull,Transfer,Take'] = [[Пусть лучше
	{#if_hint/#first,plural,стоят,стоит} там, где
	{#if_hint/#first,plural,стоят,стоит}.]];
}:attr 'static'

Prop = Class {
	before_Default = function(s, ev)
		p ("Тебе нет дела до ", s:noun 'рд', ".")
	end;
}:attr 'scenery'

function init()
	walk 'home'
end
-- https://kosmolenta.com/index.php/488-2015-01-15-moon-seven
pl.description = function(s)
	p [[Тебя зовут Борис.]];
	if here() ^ 'home' then
		p [[Ты очень напряжён и эмоционально измотан.]]
	end
end
function clamp(v, l)
	if v > l then v = l end
	return v
end
function inc_clamp(v, l)
	v = v + 1
	return clamp(v, l)
end
function inc(v)
	return v + 1
end
function in_t(v, t)
	for _, vv in ipairs(t) do
		if v == vv then return true end
	end
	return false
end
obj {
	-"Лариса,жена";
	nam = 'жена';
	{
		talk = {
			[1] = [[-- Так не может продолжаться вечно. Нужно решать нашу проблему... -- начинаешь ты.^
			Лариса молча смотрит куда-то в сторону.]];
			[2] = [[-- Только нужно делать это вместе. Я и ты. Не молчи, пожалуйста...^
			Лариса пожимает плечами.]];
			[3] = [[-- Ты обещала поговорить. Так давай разговаривать! Не молчи, прошу!^
			Лариса с осторожностью бросает на тебя взгляд, затем снова отводит его в сторону.]];
			[4] = [[-- Я не могу так больше. Если это конец -- давай честно признаем это... Но нельзя оставаться в этом тупике. Я с ума схожу от безысходности!^
			-- Я, я, я... Ты думаешь только о себе! Ты никогда не думал о том, что чувствую я!? -- взрывается Лариса.]];
			[5] = [[-- Хорошо, давай поговорим об этом. Что с тобой? Почему мы становимся чужими людьми? Что я делаю не так?^
			-- Ты опять о себе... -- в голосе Ларисы чувствуется горечь.]];
			[6] = [[-- А как ты хотела? Я чувствую, что я живу в пустоте. В абсолютном вакууме! В чём смысл такой жизни? Ну, что ты молчишь?^
			-- А ты не думал, чем живу я? Ты только используешь меня. Для своего комфорта. Я -- просто твоя служанка и всегда ей была! -- Лариса вот-вот расплачется.]];
			[7] = [[-- Это какое-то дерьмо! Дело не во мне, я такой-же, каким был 17 лет назад. Это в тебе что-то изменилось! Я привык решать проблемы, решу и эту! -- ты почти теряешь контроль над собой.^
			-- Как всегда, силой? Сломать всё? Давай, ты это умеешь! -- от хлёстких слов Ларисы тебя заливает волнами обиды.]];
			[8] = [[-- Если наши отношения мертвы, то их лучше закончить, чем жить в аду! Артур уже взрослый, он поймёт... Я отдам вам квартиру и уеду, всем будет легче... -- ты почти сам веришь своим словам. Но тебе кажется, что их произносит кто-то другой.^
			-- Ты предал нашу любовь! Растоптал всё! Космонавт! -- в последних словах Ларисы слышится издёвка.]];
			[9] = [[-- Да что ты от меня хочешь, чёрт возьми?!!^
			-- Я уже больше ничего не хочу...]];
			[10] = [[-- Хорошо, выскажись ты, я выслушаю. Пойму. Главное, не молчи!^
			-- Приказываешь, как у себя, там? -- Лариса в первый раз подняла свой взгляд и тебе стало мучительно больно.]];
			[11] = [[-- Я не приказываю, я просто устал. Посмотри на меня? Мой полёт на Луну будет последним.^
			-- Я тоже устала. Давай просто пойдём спать... -- с мольбой в голосе говорит Лариса.]];
			[12] = [[-- И снова оставим проблему нерешённой? Тебя устраивает это?^
			-- Я -- мертва. Мне уже всё-равно. Просто оставь меня в покое.]];
			[13] = [[-- Я хотел бы исправить всё. Но мне нужно понимать, что происходит.^
			-- Ты должен чувствовать. В этом проблема. Ты больше не чувствуешь.]],
			[14] = [[-- Я такой же, каким был всегда! А вот ты...^
			-- Я тоже больше ничего не чувствую... -- почти шёпотом произносит Лариса.]];
			[15] = [[-- Всё это повторялось тысячу раз. Я больше не могу, извини. Когда я вернусь...^
			Звук телефонного вызова прервал тебя.^
			-- Ну, возьми трубку, ответь. Что же ты. -- с этими словами Лариса вышла из комнаты.
			]];
		};
	};
	talk_step = 0;
	description = [[Тебе кажется, что Лариса
	почти не изменилась за все эти 17 лет. Но в последние годы ваш брак трещит по швам.
	Раздражение, затаённые обиды и ссоры. Ты задыхаешься от отсутствия любви, как и она. Что стало причиной разлада? Твоя работа? Её усталость? Можно ли вырваться из этой западни?]];
	found_in = 'home';
	talk2 = false;
	before_Talk = function(s)
		if s.talk2 then
			if isDaemon'телефон' then
				p [[-- Какая-то пелена. Не понимаю, что на меня нашло...^
				-- Телефон звонит. Наверное, это по работе. -- говорит Лариса. -- Ответишь?]]
				return
			end
			p [[-- Давай попробуем ещё раз? С чистого листа. -- произносишь ты. И сразу же ощущаешь как будто вязкая тёмная пелена вдруг спала с твоего сердца.^
			Лариса ничего не ответила, но только крепче прижалась к тебе.^
			-- Прости меня...]];
			DaemonStart'телефон'
			return
		end
		s.talk_step = inc_clamp(s.talk_step, #s.talk)
		if s.talk_step == #s.talk then
			DaemonStart'телефон'
			remove(s)
		end
		p(s.talk[s.talk_step])
	end;
	['before_Touch,Kiss,Taste'] = function(s)
		if s.talk2 then
			p [[Ты поглаживаешь Ларису по волосам.]]
			return
		end
		if in_t(s.talk_step, {3, 10, 11, 13, 14}) then
			p [[Внезапно, поддавшись интуиции, ты подходишь к Ларисе и обнимаешь её. Она делает неуверенное движение, пытаясь отстраниться, но затем прижимается к тебе.]]
			s.talk2 = true
		else
			p [[Ты пытаешься обнять жену, но она отстраняется от тебя. Как всегда, ты выбрал неудачный момент.]]
		end
	end;
}:attr'scenery,animate';

room {
	nam = 'home';
	title = "гостиная";
	-"гостиная,комната";
	out_to = function()
		p [[Ты хочешь решить проблему, а не бежать от неё.]];
	end;
	dsc = function(s)
		p [[Ты находишься в гостиной.]]
		if _'#win':has'open' then
			p [[Сквозь окна ты видишь ночную тьму.]]
		else
			p [[Сквозь закрытые окна ты видишь ночную тьму.]];
		end
		if seen 'жена' then
			p [[В комнате только ты и твоя жена Лариса.]]
			if _'жена'.talk_step == 0 then
				p [[Ты собираешься с духом, чтобы поговорить с Ларисой о ваших отношениях.^^]]
				p [[В комнате царит напряжённая тишина.]]
			end
		end
	end;
	before_Listen = function(s)
		if isDaemon 'телефон' then
			p [[Ты слышишь мелодию вызова.]]
			return
		end
		return false
	end;
	["before_Ring,Answer"] = function(s)
		if isDaemon 'телефон' then
			DaemonStop 'телефон'
			walk 'разговор'
			return
		end
		return false
	end;
}: with {
	Ephe { -"тьма,ночь"; description = [[Уже совсем поздно.]] };
	Ephe { -"тишина"; };
	obj {
		nam = '#win';
		-"окна|окно";
		description = "За окнами -- тьма.";
		before_LetIn = "Неуместная мысль.";
	}:attr 'static,concealed,openable,enterable';
	Furniture {
		-"столик,стеклянный столик,стол";
		description = [[Стеклянный столик стоит посреди гостиной.]];
		before_Enter = [[Столик хрупкий, лучше этого не делать.]];
	}:attr 'supporter':with {
		obj {
			-"телефон,мобильный|трубка";
			nam = 'телефон';
			init_dsc = "На столике лежит телефон.";
			description = [[Твой мобильный телефон.]];
			before_Take = function(s)
				if isDaemon(s) then
					here():before_Answer()
					return
				end
				return false
			end;
			before_SwitchOff = [[Ты должен оставаться на связи.]];
			daemon = function(s)
				p [[Ты слышишь как звонит твой мобильный.]];
			end;
		}:attr 'switchable,on'
	};
}

cutscene {
	nam = "разговор";
	enter = function(s)
		remove 'телефон'
	end;
	text = {
		[[-- Да, слушаю!^
		-- Борис, извини, что так поздно. Но тут такое дело... Старт переносится. Тебе нужно завтра приехать.]];
		[[-- Завтра? Что произошло?^
		-- Я понимаю, выходные... Но у нас ситуация... Потеряна связь с лунной вахтой. Была надежда, что это временные проблемы, но они не выходят на связь уже два дня. Никаких сигналов от них.]];
		[[-- Что это может означать? Метеорит?^
		-- Неизвестно. Принято решение перенести старт Луны-9. Китайцы настаивают, да и мы хотим помочь ребятам, если... Если они ещё живы.]];
		[[-- Когда?^
		-- Приезжай, всё узнаешь. И.. Передай Ларисе мои извинения... У тебя всё в порядке? Голос какой-то...]];
		[[-- Всё в порядке, Саша, завтра буду.^
		-- Хорошо, до встречи.]],
		[[Ты смотришь в ночное окно. В затянутом дымке осеннем небе не видно звёзд.]];
	};
	next_to = 'title'
}

cutscene {
	nam = 'title';
	title = "Луна-9";
	dsc = [[11 ноября 2043 года пилотируемый космический корабль "Корвет-3" успешно достиг орбиты Луны. На 17 дней раньше ранее запланированного срока.^^
	Командир: Борис Громов^
	Пилот командного модуля: Сергей Чернов^
	Пилот лунного модуля: Александр Катаев^^
	Миссия: cмена вахты на российско-китайской лунной базе "Луна-9". Выяснение причины пропажи связи, спасение экипажа.
	]];
}
-- эпизод 1
-- вход в тень Луны, видны звёзды
-- просыпается. Остальные спят.
-- 562км от Луны, 2,336 км/с скорость
-- 75 часов, 41 минута, 23 секунды
-- через 8 минут.
-- развернуть корабль вперёд двигателями.
-- вкл двигатель на 5.57
-- эллиптическая орбита 114, 313
-- 17 секунд работы двигателя
-- круговая 99 (периселение), 120км(апоселение)
-- проверка лунного модуля
-- стёкла? течь?

-- эпизод 2 -- посадка,
-- гора Малаперт, "Пик вечного света" у Южного полюса.
-- 89% светло, затенённые кратеры (лёд)
-- Кратер Малаперт имеет полигональную форму и практически полностью разрушен. Вал представляет собой нерегулярное кольцо пиков окружающих чашу кратера, западная часть вала перекрыта безымянным кратером. Юго-западная часть вала формирует возвышение в виде хребта вытянутого с востока на запад высотой около 5000 м неофициально именуемое пиком Малаперта (иногда Малаперт Альфа). Дно чаши пересеченное, со множеством холмов. Вследствие близости к южному полюсу часть кратера практически постоянно находится в тени, что затрудняет наблюдения.
-- На пике -- передатчик для связи с Землёй.
-- Там же -- солнечная батарея.
-- Собираемая конструкция - в тени кратера.

-- Эпизод 3
-- По радиомаякам идут пешком или едут к Луне-9
