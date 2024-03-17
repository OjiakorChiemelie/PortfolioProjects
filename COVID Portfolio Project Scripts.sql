-- See All available data
SELECT *
FROM PortfolioProject..CovidDeaths

SELECT DISTINCT(location) 
FROM CovidDeaths

SELECT DISTINCT(continent) 
FROM CovidDeaths

SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent is NULL 

--Select Data to be used
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject.dbo.CovidDeaths
ORDER BY 1,2

-- Looking at Total Cases Vs Total Deaths
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject.dbo.CovidDeaths
ORDER BY 1,2

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
ORDER BY 1,2

/*
--check the datatypes of our coulmns:
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'CovidDeaths'

--Convert the necessary ones to Float:
ALTER TABLE CovidDeaths
ALTER COLUMN total_cases FLOAT

ALTER TABLE CovidDeaths
ALTER COLUMN total_deaths FLOAT
*/

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE total_deaths/total_cases is NOT NULL
ORDER BY 1,2
--Shows the likelihood of dying if you contract covid in your country
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE location like '%state%'
ORDER BY 1,2

-- Looking at Total Cases vs Population
--Shows what percentage of population got covid
SELECT location, date, population, total_cases, (total_cases/population)*100 AS CasePercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE location like '%state%'
ORDER BY 1,2

--Looking at Countries with Higehst infection rate compared to population
SELECT location, population, MAX(total_cases) AS HighestInfectionCountPerDay, MAX((total_cases/population)*100) AS CasePercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent is NOT NULL
GROUP BY location, population
ORDER BY CasePercentage DESC

-- Showing Countries with highest Death Count per Population
SELECT location, MAX(total_deaths) AS HighestDeathCountPerDay
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent is NOT NULL
GROUP BY location
ORDER BY HighestDeathCountPerDay DESC
--Looking at Continents
SELECT continent, MAX(total_deaths) AS HighestDeathCountPerDay
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent is NOT NULL
GROUP BY continent
ORDER BY HighestDeathCountPerDay DESC

SELECT location, MAX(total_deaths) AS HighestDeathCountPerDay
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent is NULL
GROUP BY location
ORDER BY HighestDeathCountPerDay DESC

-- Showing Continent with highest Death Count per Population
SELECT continent, MAX(total_deaths) AS HighestDeathCountPerDay
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent is NOT NULL
GROUP BY continent
ORDER BY HighestDeathCountPerDay DESC

-- Globa Numbers

SELECT date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent is not null
ORDER BY 1,2
-- This gives sum of new cases/deaths in the world everyday
SELECT date, SUM(new_cases), SUM(new_deaths) --, (SUM(new_deaths)/SUM(new_cases))*100 AS DeathPercenage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1

SELECT SUM(new_cases), SUM(new_deaths) 
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent is not null
ORDER BY 1


/* CovidVaccination Table */

SELECT *
FROM CovidVaccinations

/* Combining our Two tables */

SELECT *
FROM PortfolioProject..CovidDeaths AS dea 
JOIN PortfolioProject.dbo.CovidVaccinations vac
     ON dea.location = vac.location
	 AND dea.date = vac.date

-- Looking at Total population vs vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM PortfolioProject..CovidDeaths AS dea 
JOIN PortfolioProject.dbo.CovidVaccinations vac
     ON dea.location = vac.location
	 AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 1,2


SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS float)) OVER (PARTITION BY dea.location) AS TotalPeoplebyLocation
FROM PortfolioProject..CovidDeaths AS dea 
JOIN PortfolioProject.dbo.CovidVaccinations vac
     ON dea.location = vac.location
	 AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 1,2

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS float)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths AS dea 
JOIN PortfolioProject.dbo.CovidVaccinations vac
     ON dea.location = vac.location
	 AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 1,2

-- Using CTE

WITH PopvsVac AS 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS float)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths AS dea 
JOIN PortfolioProject.dbo.CovidVaccinations vac
     ON dea.location = vac.location
	 AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT continent, location, date, population, RollingPeopleVaccinated, (RollingPeopleVaccinated/population)*100
FROM PopvsVac
ORDER BY 2,3

-- Using Temp Table
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
Population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS float)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths AS dea 
JOIN PortfolioProject.dbo.CovidVaccinations vac
     ON dea.location = vac.location
	 AND dea.date = vac.date
--WHERE dea.continent IS NOT NULL

SELECT *,  (RollingPeopleVaccinated/population)*100
FROM #PercentPopulationVaccinated
ORDER BY 2,3



-- Creating View to store data for later visualisations

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS float)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths AS dea 
JOIN PortfolioProject.dbo.CovidVaccinations vac
     ON dea.location = vac.location
	 AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *
FROM PercentPopulationVaccinated