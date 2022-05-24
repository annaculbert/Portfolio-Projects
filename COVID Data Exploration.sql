/*
Covid 19 Data Exploration

Data exploration of the 'Our World in Data COVID-19 dataset' to identify trends and gather global and continental statistics 
in preparation of creating visualizations in Tableau

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

Select *
From [Portfolio Project 1]..CovidDeaths
Where continent is not null
order by 3,4


-- Select Data that we are going to be starting with


Select Location, date, total_cases, new_cases, total_deaths, population
From [Portfolio Project 1]..CovidDeaths
Where continent is not null
order by 1,2


-- Total Cases vs Total Deaths
-- Shows the liklihood of dying if you contract COVID in your country

Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
From [Portfolio Project 1]..CovidDeaths
Where continent is not null
AND Location like '%states%'
order by 1,2


-- Total Cases vs. Population
-- Shows what percentage of population contracted COVID

Select Location, date, total_cases, population, (total_cases/population)*100 AS ContractionPercentage
From [Portfolio Project 1]..CovidDeaths
order by 1,2


-- Counties with Hightest Infection Rate compared to Population

Select Location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases)/population)*100 AS PercentPopulationInfected
From [Portfolio Project 1]..CovidDeaths
Group by Location, population
order by PercentPopulationInfected DESC


-- Countries with highest death count per population

Select Location, population, MAX(cast(total_deaths as int)) AS HighestDeathCount
From [Portfolio Project 1]..CovidDeaths
Where continent is not null
Group by Location, population
order by HighestDeathCount DESC


-- BREAKING THINGS DOWN BY CONTINENT (rather than country)

-- Showing continents with the highest death count per population

Select continent, MAX(cast(total_deaths as int)) AS HighestDeathCount
From [Portfolio Project 1]..CovidDeaths
Where continent is not null
Group by continent
order by HighestDeathCount DESC

-- GLOBAL NUMBERS

-- Total Global Cases, Total Deaths, & Death Percentage:

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
From [Portfolio Project 1]..CovidDeaths
Where continent is not null
Order by 1,2

-- Daily Global Cases, Deaths, Percentage:
Select date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
From [Portfolio Project 1]..CovidDeaths
Where continent is not null
Group by date
Order by 1,2

-- Total Population vs. Vaccinations
-- Shows Percentage of Population that has received at least one COVID vaccine

Select dea.continent, dea.location, cast(dea.date as date) Date, dea.population, vac.new_vaccinations, 
	SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order by dea.location, 
	cast(dea.date as date)) as RollingPeopleVaccinated
From [Portfolio Project 1]..CovidDeaths Dea
Join [Portfolio Project 1]..CovidVaccinations Vac
	On dea.location = vac.location and
	dea.date = vac.date
Where dea.continent is not null
Order by 2, 3

-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, new_vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, cast(dea.date as date), dea.population, vac.new_vaccinations, 
	SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order by dea.location, 
	cast(dea.date as date)) as RollingPeopleVaccinated
From [Portfolio Project 1]..CovidDeaths Dea
Join [Portfolio Project 1]..CovidVaccinations Vac
	On dea.location = vac.location and
	dea.date = vac.date
Where dea.continent is not null
)
Select*, (RollingPeopleVaccinated/population)*100 as RollingPercentageVaccinated
From PopvsVac


-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, cast(dea.date as date), dea.population, vac.new_vaccinations, 
	SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location Order by dea.location, 
	cast(dea.date as date)) as RollingPeopleVaccinated
From [Portfolio Project 1]..CovidDeaths Dea
Join [Portfolio Project 1]..CovidVaccinations Vac
	On dea.location = vac.location and
	dea.date = vac.date

Select*, (RollingPeopleVaccinated/population)*100 as RollingPercentageVaccinated
From #PercentPopulationVaccinated
Where Location like '%states'

/* 
Summary:
* The death percentage (total deaths / total cases) in the United States has gradually decreased in the past 2 years. The highest it was at was nearly 11% in 
March of 2020 and it has now declined to about 1.2%.
* The country with the highest infection rate compared to their population is Faeroe Islands with 70.65% of their population infected. The United States falls
as the 52nd highest country with 24.1%.
* Although the United States is 52nd on the above named list, it is ranked as number one for highest death count. At the end of March 2022, this was at 980,638
people. (In May of 2022, the U.S. passed 1 million reported deaths from COVID-19).
* In March of 2022, the global death percentage from COVID-19 was at 1.25%.
* This data set reports that people began to receive their COVID-19 vaccinations on December 14, 2020. As of March 2022, 560,793,296 vaccinations have been given
in the United States (including 2nd and 3rd doses).

