--Data Import Tests
SELECT * 
FROM [Portfolio Project]..CovidDeaths
ORDER BY 3,4

SELECT * 
FROM [Portfolio Project]..CovidVaccinations
ORDER BY 3,4


-- Basic Data selection example
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM [Portfolio Project]..CovidDeaths
ORDER BY 1,2

-- Total Cases vs Total Deaths in the US
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
FROM [Portfolio Project]..CovidDeaths
WHERE location like '%united states%'
ORDER BY 2

-- Total Cases vs Population in the US
--	 What percentage of the US population have been infected with COVID?
SELECT date, total_cases, population, (total_cases/population)*100 as population_infection_percentage
FROM [Portfolio Project]..CovidDeaths
WHERE location like '%united states%'
ORDER BY 2


-- Countries with the Highest Infection Rate vs Population
SELECT location,  population, MAX(total_cases) as highest_infection_count, (MAX(total_cases)/population)*100 as population_infection_percentage
FROM [Portfolio Project]..CovidDeaths
WHERE continent is not null
GROUP BY location, population
HAVING MAX(total_cases) is not null and population is not null
ORDER BY 4 desc

-- Countries with the Highest Death Rate vs Population
SELECT location,  population, MAX(cast(total_deaths as int)) as total_death_count, (MAX(cast(total_deaths as int))/population)*100 as population_death_rate
FROM [Portfolio Project]..CovidDeaths
WHERE continent is not null
GROUP BY location, population
HAVING MAX(total_deaths) is not null and population is not null
ORDER BY 4 desc

-- Continents with the Highest Death Count
SELECT continent, MAX(cast(total_deaths as int)) as total_death_count
FROM [Portfolio Project]..CovidDeaths
WHERE continent is not null
GROUP BY continent
order by total_death_count desc


-- Global Numbers per Day
SELECT  date, sum(new_cases) as daily_cases, sum(cast(new_deaths as int)) as daily_deaths, (sum(cast(new_deaths as int))/sum(new_cases))*100 as daily_death_rate
FROM [Portfolio Project]..CovidDeaths
WHERE continent is not null
group by date
order by date



-- Global Numbers - Total
SELECT  sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, (sum(cast(new_deaths as int))/sum(new_cases))*100 as global_death_rate
FROM [Portfolio Project]..CovidDeaths
WHERE continent is not null


-- Rolling Total Vaccinations by Country
WITH pop_vac (continent, location, date, population, new_vaccinations, rolling_total_vaccinations)
AS

(
SELECT  dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations, 
	sum(cast(vax.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER by dea.location, dea.date) as rolling_total_vaccinations
FROM [Portfolio Project]..CovidDeaths as dea
JOIN [Portfolio Project]..CovidVaccinations as vax
	on dea.location = vax.location
	and dea.date = vax.date
WHERE dea.continent is not null
)

SELECT *, (rolling_total_vaccinations/population)*100 as percent_pop_vaccinated
FROM pop_vac
ORDER BY 2,3


-- Rolling Total Vaccinations by Country - Temp Table
DROP TABLE IF EXISTS #pop_vac 
CREATE TABLE #pop_vac 
(
	continent nvarchar(255), 
	location nvarchar(255), 
	date datetime, 
	population numeric, 
	new_vaccinations numeric, 
	rolling_total_vaccinations numeric
)

INSERT INTO #pop_vac
	SELECT  dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations, 
		sum(cast(vax.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER by dea.location, dea.date) as rolling_total_vaccinations
	FROM [Portfolio Project]..CovidDeaths as dea
	JOIN [Portfolio Project]..CovidVaccinations as vax
		on dea.location = vax.location
		and dea.date = vax.date
	WHERE dea.continent is not null

SELECT *, (rolling_total_vaccinations/population)*100 as percent_pop_vaccinated
FROM #pop_vac
ORDER BY 2,3


--Saving Tables for later use
-- Rolling Total Vaccinations by Country
CREATE VIEW pop_vac AS
	SELECT  dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations, 
		sum(cast(vax.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER by dea.location, dea.date) as rolling_total_vaccinations
	FROM [Portfolio Project]..CovidDeaths as dea
	JOIN [Portfolio Project]..CovidVaccinations as vax
		on dea.location = vax.location
		and dea.date = vax.date
	WHERE dea.continent is not null

-- Total Cases vs Population in the US
--	 What percentage of the US population have been infected with COVID?
CREATE VIEW us_cases as 
	SELECT date, total_cases, population, (total_cases/population)*100 as population_infection_percentage
	FROM [Portfolio Project]..CovidDeaths
	WHERE location like '%united states%'


-- Global Numbers per Day
CREATE VIEW daily_cases_globally as
SELECT  date, sum(new_cases) as daily_cases, sum(cast(new_deaths as int)) as daily_deaths, (sum(cast(new_deaths as int))/sum(new_cases))*100 as daily_death_rate
	FROM [Portfolio Project]..CovidDeaths
	WHERE continent is not null
	GROUP BY date
