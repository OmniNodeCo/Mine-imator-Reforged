#include "Common.hpp"

namespace CppProject
{
	void Printer::Line(QString text)
	{
	#if RELEASE_MODE
		// Log next to the executable so it is easy to find and attach to bug reports
		QString logFile = QCoreApplication::applicationDirPath() + "/log.txt";
	#else
		QString logFile = QDir::currentPath() + "/log.txt";
	#endif
		QFile file(logFile);
		AddPerms(file);
		if (!file.open(QFile::Append))
			return;

		int ind = indent;
		while (ind--)
			text.insert(0, "   ");

		static QLocale localFormat;
		text.insert(0, QDateTime::currentDateTime().toString(localFormat.timeFormat(QLocale::LongFormat)) + " ");

		QTextStream stream(&file);
		stream << text << "\n";

	#if DEBUG_MODE
		std::cout << text.toStdString() << std::endl;
	#endif
	}

	void Printer::Warning(QString text)
	{
		Printer::Line("[WARNING] " + text);
	}

	void Printer::Fatal(QString text)
	{
		Printer::Line("[FATAL ERROR] " + text);
		throw text;
	}

	RealType Random::Get(RealType max)
	{
		ThreadData& data = threadData[omp_get_thread_num()];
		return data.dist(data.gen) * max;
	}

	void Random::Set(IntType seed)
	{
		ThreadData& data = threadData[omp_get_thread_num()];
		data.seed = seed;
		data.gen = std::mt19937(data.seed);
	}

	uint16_t Random::GetSeed()
	{
		ThreadData& data = threadData[omp_get_thread_num()];
		return data.seed;
	}
}