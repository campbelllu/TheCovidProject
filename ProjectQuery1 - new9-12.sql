--All data
SELECT  *  
FROM PortfolioProject..CovidDeaths
ORDER BY 3,4

--Specific Data that we are going to be using
SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2 --orders by first select categories

--Looking at Total Cases vs Total Deaths
--Shows likelihood of dying if infected with covid in the United States
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location like '%states%' AND continent is not null
ORDER BY 1,2 

--Looking at Total Cases vs Population
--Shows percentage of population infected with Covid
SELECT Location, date, total_cases, population, (total_cases/population)*100 AS PercentInfected
FROM PortfolioProject..CovidDeaths
WHERE location like '%states%' AND continent is not null
ORDER BY 1,2 

-- Looking at countries with highest infection rate compared to population
SELECT Location, population, date, MAX(total_cases) AS MaxInfectionCount, MAX(total_cases/population)*100 AS MaxPercentInfected
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY Location, population, date
ORDER BY 4 DESC

-- Showing countries with highest death count per population
SELECT Location, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY Location
ORDER BY TotalDeathCount DESC

--Breaking down highest death count per population per continent; correct version
SELECT location, SUM(cast(total_deaths as int)) AS TotalDeathCount --was MAX() before step 2
FROM PortfolioProject..CovidDeaths
WHERE continent is null AND location NOT IN('World', 'European Union', 'International') --added second conditional step 2
GROUP BY location
ORDER BY TotalDeathCount DESC

--Breaking down highest death count per population per continent; incorrect version, possibly
SELECT continent, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount DESC

--Looking at Most current Mortality Rates in the states(see where statement)
SELECT Location, population, MAX(total_cases/population)*100 AS MaxPercentInfected, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE date >= Convert(datetime, '2021-08-25') AND Location like '%states%' AND continent is not null
GROUP BY Location, population, (total_deaths/total_cases)*100
ORDER BY 4 DESC 

--GLOBAL NUMBERS
SELECT SUM(new_cases) AS TotalCases, SUM(cast(new_deaths as int)) AS TotalDeaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
--GROUP BY date
ORDER BY 1,2

--Example Join to compare vaccination rates
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vacs.total_vaccinations, 
	SUM(CONVERT(int,vacs.new_vaccinations)) OVER (Partition by deaths.location ORDER BY deaths.location, deaths.date) AS RollingPeopleVaxd
FROM PortfolioProject..CovidDeaths deaths
JOIN PortfolioProject..FullCovidData vacs
	ON deaths.location=vacs.location
	and deaths.date = vacs.date
WHERE deaths.continent IS NOT NULL
ORDER BY 2,3

--Using Common Table Expression(CTE)
WITH PopvsVac (Continent, Location, Date, Population, New_Vacs, RollingPeopleVaxd)
as
(
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vacs.new_vaccinations, 
	SUM(CONVERT(int,vacs.new_vaccinations)) OVER (Partition by deaths.location ORDER BY deaths.location, deaths.date) AS RollingPeopleVaxd
FROM PortfolioProject..CovidDeaths deaths
JOIN PortfolioProject..FullCovidData vacs
	ON deaths.location=vacs.location
	and deaths.date = vacs.date
WHERE deaths.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaxd/Population)*100 AS RollingPercent
FROM PopvsVac
WHERE (RollingPeopleVaxd/Population)*100 IS NOT NULL

--USING TEMP TABLE
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaxd numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vacs.new_vaccinations, 
	SUM(CONVERT(int,vacs.new_vaccinations)) OVER (Partition by deaths.location ORDER BY deaths.location, deaths.date) AS RollingPeopleVaxd
FROM PortfolioProject..CovidDeaths deaths
JOIN PortfolioProject..FullCovidData vacs
	ON deaths.location=vacs.location
	and deaths.date = vacs.date
WHERE deaths.continent IS NOT NULL

--Look at our created table with specified percentage requests
SELECT *, (RollingPeopleVaxd/Population)*100 AS RollingPercent
FROM #PercentPopulationVaccinated
WHERE (RollingPeopleVaxd/Population)*100 IS NOT NULL
AND New_Vaccinations IS NOT NULL

--Creating a View to store data for later visualization
Create View PPV as
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vacs.new_vaccinations, 
	SUM(CONVERT(int,vacs.new_vaccinations)) OVER (Partition by deaths.location ORDER BY deaths.location, deaths.date) AS RollingPeopleVaxd
FROM PortfolioProject..CovidDeaths deaths
JOIN PortfolioProject..FullCovidData vacs
	ON deaths.location=vacs.location
	and deaths.date = vacs.date
WHERE deaths.continent IS NOT NULL
--ORDER BY 2,3

--Testing above view with previous query
SELECT *, (RollingPeopleVaxd/Population)*100 AS RollingPercent
FROM PPV
WHERE (RollingPeopleVaxd/Population)*100 IS NOT NULL
AND New_Vaccinations IS NOT NULL
