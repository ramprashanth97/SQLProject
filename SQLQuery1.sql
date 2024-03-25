-- Selecting the data required.
select location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject..CovidDeaths
order by 1,2

-- Looking at Total Cases vs. Total Deaths
select location, date, total_cases, total_deaths, (CAST(total_deaths AS float) / CAST(total_cases AS float))*100 as DeathPercentage
from PortfolioProject..CovidDeaths
where location like '%states%'
order by 1,2

-- Lookin at Total Cases vs. Population
select location, date, total_cases, population, (CAST(total_cases AS float) / CAST(population AS float))*100 as InfectionRate
from PortfolioProject..CovidDeaths
where location like '%states%'
order by 1,2

-- Looking at Countries with highest Infection count compared to Population
select location, population, MAX(total_cases) as HighestInfectionCount, (CAST(MAX(total_cases) AS float) / CAST(population AS float))*100 as MaxInfectionRate
from PortfolioProject..CovidDeaths
group by location, population
order by MaxInfectionRate desc

-- Looking at Total deaths by Country
select location, MAX(CAST(total_deaths AS float)) as TotalDeathCount
from PortfolioProject..CovidDeaths
where continent is not null
group by location
order by TotalDeathCount desc

-- Looking at Total deaths by Continent
select continent, MAX(CAST(total_deaths AS float)) as TotalDeathCount
from PortfolioProject..CovidDeaths
where continent is not null
group by continent
order by TotalDeathCount desc

-- Global numbers
select date, sum(new_cases) as TotalCases, sum(new_deaths) as TotalDeaths, 
(sum(new_deaths)/NULLIF(sum(new_cases), 0))*100 as DeathPercentage
from PortfolioProject..CovidDeaths
where continent is not null
group by date
order by 1,2

-- Joining the two Datasets on location and date
select *
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date

-- Looking at Total Population vs. Total Vaccinations (CTE method)
with PopvsVac (continent, location, date, population, new_vaccinations, RollingVaccinations)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(cast(vac.new_vaccinations as bigint)) over (partition by dea.location order by dea.location, dea.date) as RollingVaccinations
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
)
select *, (RollingVaccinations/population)*100
from PopvsVac

-- Looking at Total Population vs. Total Vaccinations (Temp table method)
drop table if exists #PercentPopulationVaccinated
create table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingVaccinations numeric
)
insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(cast(vac.new_vaccinations as bigint)) over (partition by dea.location order by dea.location, dea.date) as RollingVaccinations
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null

select *, (RollingVaccinations/Population)*100 as VaccinationPercentage
from #PercentPopulationVaccinated

-- Creating views for later visualizations
create view PercentPopulationVaccinated as 
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
sum(cast(vac.new_vaccinations as bigint)) over (partition by dea.location order by dea.location, dea.date) as RollingVaccinations
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null