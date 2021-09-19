///////////////////////////////////////////////////////////////////////////////
//
// Модуль генерации описаний файлов 1с в формате EDT
//
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// ПРОГРАММНЫЙ ИНТЕРФЕЙС
///////////////////////////////////////////////////////////////////////////////

// Формирует служебные параметры необходимые для дальнейшей работы генератора
//
// Параметры:
//   ВерсияПлатформы - Строка - Версия платформы 1с под которую создается описание
//   ГенерацияРасширения - Булево - Флаг создания расширения
//
//  Возвращаемое значение:
//   Структура - Служебные параметры генератора
//
Функция СоздатьПараметрыГенерации(ВерсияПлатформы, ГенерацияРасширения) Экспорт
	
    Если Лев(ВерсияПлатформы, 6) = "8.3.10" Тогда

        ВерсияВыгрузки = "2.4";

    Иначе

        ВызватьИсключение "Неизвестная версия платформы";

    КонецЕсли;

	ПараметрыГенерации = Новый Структура();
	ПараметрыГенерации.Вставить("ВерсияПлатформы", ВерсияПлатформы);
	ПараметрыГенерации.Вставить("ВерсияВыгрузки", ВерсияВыгрузки);
	ПараметрыГенерации.Вставить("ГенерацияРасширения", ГенерацияРасширения = Истина);
	
	Возврат ПараметрыГенерации;
	
КонецФункции

// Метод создает базовое описание корневого объекта, в которое потом можно добавлять объекты и т.д.
//
// Параметры:
//	ОписаниеРасширения - Структура - Описание расширения, наименование синоним и прочее
//	ТипОбъекта - Строка - Каноническое имя типа (Configuration, Extension...)
//	ИмяФайла - Строка - Имя файла описания объекта, в который будут записаны данные
//	ПараметрыГенерации - Структура - Общие данные/настройки необходимые для генерации 
//
Функция СоздатьОписаниеКорневогоОбъекта(ОписаниеРасширения, ТипОбъекта, ИмяФайла, ПараметрыГенерации) Экспорт

	НормТипОбъекта = ТипыОбъектовКонфигурации.НормализоватьИмя(ТипОбъекта);
	
	ЗаписьConfiguration = СоздатьЗапись("Configuration", ПараметрыГенерации, ИмяФайла);
	
	ГенераторОписанийОбщий.ЗаписатьДанные(ЗаписьConfiguration, ОписаниеРасширения, НормТипОбъекта, ЭтотОбъект);
	
	Если ТипыОбъектовКонфигурации.ИмяТипаРасширения() = НормТипОбъекта Тогда
			
		ЗаписьConfiguration.ЗаписатьНачалоЭлемента("extension");
		ЗаписьConfiguration.ЗаписатьАтрибут("xsi:type", "mdclassExtension:ConfigurationExtension");
		
		ЗаписьConfiguration.ЗаписатьКонецЭлемента(); // extension
		
	КонецЕсли;

	Для Каждого uid из ГенераторОписанийОбщий.ПолучитьUIDДляГенерацииРасширения() Цикл
		
		ЗаписьConfiguration.ЗаписатьНачалоЭлемента("containedObjects");
		ЗаписьConfiguration.ЗаписатьАтрибут("classId", uid);
		ЗаписьConfiguration.ЗаписатьАтрибут("objectId", Строка(Новый УникальныйИдентификатор()));
        ЗаписьConfiguration.ЗаписатьКонецЭлемента(); // containedObjects

	КонецЦикла;
	
	Возврат ЗаписьConfiguration;

КонецФункции

// Записывает описание объекта в поток
//
// Параметры:
//   Запись - ЗаписьXML - Поток записи
//   ТипОбъекта - Строка - Тип объекта конфигурации, см ТипыОбъектовКонфигурации, ОбъектыКонфигурации.md
//   СвойстваОбъекта - Структура - Данные объекта
//
Процедура ЗаписатьСвойства(Запись, ТипОбъекта, СвойстваОбъекта) Экспорт
	
	ГенераторОписанийОбщий.ЗаписатьДанные(Запись, СвойстваОбъекта, ТипОбъекта, ЭтотОбъект);
	
КонецПроцедуры

// Метод регистрирует в конфигурации объект метаданных.
// Проверок на существование объекта нет
//
// Параметры:
//  ОбъектКонфигурации - СтрокаТаблицыЗначений - Описание объекта конфигурации. См. СтруктурыОписаний.ТаблицаОписанияОбъектовКонфигурации
//	ЗаписьConfiguration - ЗаписьXML - Поток записи описания
//
Процедура ЗарегистрироватьОбъектВКонфигурации(ОбъектКонфигурации, ЗаписьConfiguration) Экспорт
	
	ИмяТипа = ТипыОбъектовКонфигурации.ОписаниеТипаПоИмени(ОбъектКонфигурации.Тип).НаименованиеКоллекцииEng;
	ИмяТипа = НРег(Лев(ИмяТипа, 1)) + Сред(ИмяТипа, 2);

	ИмяОбъекта = СтрШаблон("%1.%2", ОбъектКонфигурации.Тип, ОбъектКонфигурации.Наименование);
	ОбработкаXML.ЗаписатьЗначениеXML(ЗаписьConfiguration, ИмяТипа, ИмяОбъекта);
	
КонецПроцедуры

// Записывает служебную информацию об уидах платформенных типов
//
// Параметры:
//   Запись - ЗаписьXML - Поток записи
//   ИмяОбъекта - Строка - Имя объекта конфигурации
//   ТипОбъекта - Строка - Тип объекта конфигурации, см ТипыОбъектовКонфигурации, ОбъектыКонфигурации.md
//
Процедура ЗаписатьПорождаемыеТипы(Запись, ИмяОбъекта, ТипОбъекта) Экспорт
	
	ПорождаемыеТипы = ТипыОбъектовКонфигурации.ОписаниеТипаПоИмени(ТипОбъекта).ПорождаемыеТипы;

	Если ПорождаемыеТипы.Количество() = 0 Тогда
		
		Возврат;
		
	КонецЕсли;
	
	Запись.ЗаписатьНачалоЭлемента("producedTypes");

	Для Каждого Тип Из ПорождаемыеТипы Цикл
		
		Запись.ЗаписатьНачалоЭлемента(НРег(Лев(Тип, 1)) + Сред(Тип, 2));
		Запись.ЗаписатьАтрибут("typeId", Строка(Новый УникальныйИдентификатор()));
		Запись.ЗаписатьАтрибут("valueTypeId", Строка(Новый УникальныйИдентификатор()));
		Запись.ЗаписатьКонецЭлемента();
	
	КонецЦикла;

	Запись.ЗаписатьКонецЭлемента();

КонецПроцедуры

// Создает xml запись описания объекта, прописывает базовые параметры
//
// Параметры:
//	ТипОбъекта - Строка - Тип объекта конфигурации на английском, например, Catalog, Configuration и т.д.
//	ПараметрыГенерации - Структура - Общие данные/настройки необходимые для генерации 
//	ИмяФайла - Строка - Имя файла описания объекта, в который будут записаны данные
//
//  Возвращаемое значение:
//   ЗаписьXML- Поток записи описания
//
Функция СоздатьЗапись(ТипОбъекта, ПараметрыГенерации, ИмяФайла = Неопределено) Экспорт

	Запись = Новый ЗаписьXML();

	ПараметрыЗаписи = Новый ПараметрыЗаписиXML("UTF-8", , , , "  ");
	
	Если ЗначениеЗаполнено(ИмяФайла) Тогда
		
		Запись.ОткрытьФайл(ИмяФайла, ПараметрыЗаписи);
		
	Иначе
		
		Запись.УстановитьСтроку(ПараметрыЗаписи);
		
	КонецЕсли;
	
    Запись.ЗаписатьОбъявлениеXML();

	Запись.ЗаписатьНачалоЭлемента(СтрШаблон("mdclass:%1", ТипОбъекта));
	
	Если ПараметрыГенерации.ГенерацияРасширения Тогда
		Запись.ЗаписатьСоответствиеПространстваИмен("xsi", "http://www.w3.org/2001/XMLSchema-instance");
	КонецЕсли;

	Запись.ЗаписатьСоответствиеПространстваИмен("mdclass", "http://g5.1c.ru/v8/dt/metadata/mdclass");

	Если ПараметрыГенерации.ГенерацияРасширения Тогда
		Запись.ЗаписатьСоответствиеПространстваИмен("mdclassExtension", "http://g5.1c.ru/v8/dt/metadata/mdclass/extension");
	КонецЕсли;
	
    Запись.ЗаписатьАтрибут("uuid", Строка(Новый УникальныйИдентификатор()));

    Возврат Запись;

КонецФункции

///////////////////////////////////////////////////////////////////////////////
// СЛУЖЕБНЫЙ ПРОГРАММНЫЙ ИНТЕРФЕЙС
///////////////////////////////////////////////////////////////////////////////

#Область МетодыЗаписиЗначений

// Записывает значение формата многонациональная строка
//
// Параметры:
//   Запись - ЗаписьXML - Поток записи
//   Значение - Строка - Записываемое значение
//
Процедура МногоязычнаяСтрока(Запись, Значение) Экспорт

	Если ТипЗнч(Значение) = Тип("Структура") Тогда 

		Для Каждого Элемент Из Значение Цикл
		
			ОбработкаXML.ЗаписатьЗначениеXML(Запись, "key", Элемент.Ключ);
			ОбработкаXML.ЗаписатьЗначениеXML(Запись, "value", Элемент.Значение);
		
		КонецЦикла;

	Иначе

		ОбработкаXML.ЗаписатьЗначениеXML(Запись, "key", "ru");
		ОбработкаXML.ЗаписатьЗначениеXML(Запись, "value", Значение);
	
	КонецЕсли;

КонецПроцедуры

// Записывает логическое значение
//
// Параметры:
//   Запись - ЗаписьXML - Поток записи
//   Значение - Булево - Записываемое значение
//
Процедура ЗначениеБулево(Запись, Значение) Экспорт

	Запись.ЗаписатьТекст(XMLСтрока(Значение));

КонецПроцедуры

// Записывает информацию о подчиненных объектах
//
// Параметры:
//   Запись - ЗаписьXML - Поток записи
//   Значение - Массив - Коллекция подчиненных объектов
//
Процедура Подчиненные(Запись, Значение) Экспорт
	
	Для Каждого ПолноеИмяЭлемента Из Значение Цикл
		
		ЧастиИмени = СтрРазделить(ПолноеИмяЭлемента, ".");
		
		ОбработкаXML.ЗаписатьЗначениеXML(Запись, ЧастиИмени[0], ПолноеИмяЭлемента);
		
	КонецЦикла;

КонецПроцедуры

#КонецОбласти

///////////////////////////////////////////////////////////////////////////////
// СЛУЖЕБНЫЕ ПРОЦЕДУРЫ И ФУНКЦИИ
///////////////////////////////////////////////////////////////////////////////
