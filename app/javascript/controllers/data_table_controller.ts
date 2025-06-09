import { BaseController } from "./base/BaseController";

interface Column {
  key: string;
  label: string;
  sortable?: boolean;
  formatter?: (value: any, row: any) => string;
}

interface TableOptions {
  searchable?: boolean;
  paginated?: boolean;
  itemsPerPage?: number;
  responsive?: boolean;
}

export default class extends BaseController {
  static targets = ["table", "searchInput", "tbody", "pagination"];
  static values = {
    columns: Array,
    data: Array,
    options: Object
  };

  declare readonly hasTableTarget: boolean;
  declare readonly hasSearchInputTarget: boolean;
  declare readonly hasTbodyTarget: boolean;
  declare readonly hasPaginationTarget: boolean;
  declare readonly tableTarget: HTMLTableElement;
  declare readonly searchInputTarget: HTMLInputElement;
  declare readonly tbodyTarget: HTMLElement;
  declare readonly paginationTarget: HTMLElement;

  declare columnsValue: Column[];
  declare dataValue: any[];
  declare optionsValue: TableOptions;

  private currentPage: number = 1;
  private sortColumn: string | null = null;
  private sortDirection: 'asc' | 'desc' = 'asc';
  private filteredData: any[] = [];

  connect(): void {
    this.filteredData = [...this.dataValue];
    this.render();
    this.setupEventListeners();
  }

  private setupEventListeners(): void {
    if (this.hasSearchInputTarget && this.optionsValue.searchable) {
      this.addManagedEventListener(this.searchInputTarget, 'input', 
        this.debounce(() => this.handleSearch(), 300)
      );
    }
  }

  private render(): void {
    this.renderTable();
    this.renderPagination();
  }

  private renderTable(): void {
    if (!this.hasTableTarget) return;

    // Render header
    const thead = this.tableTarget.querySelector('thead') || document.createElement('thead');
    thead.innerHTML = this.renderHeader();
    if (!this.tableTarget.querySelector('thead')) {
      this.tableTarget.appendChild(thead);
    }

    // Add click handlers for sortable columns
    thead.querySelectorAll('th.sortable').forEach(th => {
      this.addManagedEventListener(th, 'click', () => {
        const column = th.getAttribute('data-column');
        if (column) this.handleSort(column);
      });
    });

    // Render body
    if (this.hasTbodyTarget) {
      this.tbodyTarget.innerHTML = this.renderBody();
    }
  }

  private renderHeader(): string {
    return `
      <tr>
        ${this.columnsValue.map(col => `
          <th class="${col.sortable ? 'sortable' : ''}" data-column="${col.key}">
            ${col.label}
            ${col.sortable ? this.renderSortIcon(col.key) : ''}
          </th>
        `).join('')}
      </tr>
    `;
  }

  private renderSortIcon(column: string): string {
    const isActive = this.sortColumn === column;
    const direction = isActive ? this.sortDirection : 'none';
    
    return `
      <span class="sort-indicator ${isActive ? 'active' : ''}">
        ${direction === 'asc' ? '▲' : direction === 'desc' ? '▼' : '⇅'}
      </span>
    `;
  }

  private renderBody(): string {
    const data = this.getPaginatedData();
    
    if (data.length === 0) {
      return `
        <tr>
          <td colspan="${this.columnsValue.length}" class="text-center text-muted">
            No data available
          </td>
        </tr>
      `;
    }

    return data.map(row => `
      <tr>
        ${this.columnsValue.map(col => {
          const value = row[col.key];
          const formatted = col.formatter ? col.formatter(value, row) : value;
          return `<td data-label="${col.label}">${formatted}</td>`;
        }).join('')}
      </tr>
    `).join('');
  }

  private renderPagination(): void {
    if (!this.hasPaginationTarget || !this.optionsValue.paginated) return;

    const totalPages = Math.ceil(this.filteredData.length / (this.optionsValue.itemsPerPage || 10));
    
    if (totalPages <= 1) {
      this.paginationTarget.innerHTML = '';
      return;
    }

    let html = '';
    
    // Previous button
    html += `
      <div class="gh-page-item">
        <a href="#" class="gh-page-link ${this.currentPage === 1 ? 'disabled' : ''}" 
           data-page="${this.currentPage - 1}">&laquo;</a>
      </div>
    `;

    // Page numbers
    for (let i = 1; i <= totalPages; i++) {
      html += `
        <div class="gh-page-item">
          <a href="#" class="gh-page-link ${i === this.currentPage ? 'active' : ''}" 
             data-page="${i}">${i}</a>
        </div>
      `;
    }

    // Next button
    html += `
      <div class="gh-page-item">
        <a href="#" class="gh-page-link ${this.currentPage === totalPages ? 'disabled' : ''}" 
           data-page="${this.currentPage + 1}">&raquo;</a>
      </div>
    `;

    this.paginationTarget.innerHTML = html;

    // Add click handlers
    this.paginationTarget.querySelectorAll('.gh-page-link').forEach(link => {
      this.addManagedEventListener(link, 'click', (e) => {
        e.preventDefault();
        const page = parseInt(link.getAttribute('data-page') || '1');
        if (!link.classList.contains('disabled')) {
          this.changePage(page);
        }
      });
    });
  }

  private handleSearch(): void {
    const query = this.searchInputTarget.value.toLowerCase();
    
    if (!query) {
      this.filteredData = [...this.dataValue];
    } else {
      this.filteredData = this.dataValue.filter(row => {
        return this.columnsValue.some(col => {
          const value = String(row[col.key] || '').toLowerCase();
          return value.includes(query);
        });
      });
    }

    this.currentPage = 1;
    this.render();
  }

  private handleSort(column: string): void {
    if (this.sortColumn === column) {
      this.sortDirection = this.sortDirection === 'asc' ? 'desc' : 'asc';
    } else {
      this.sortColumn = column;
      this.sortDirection = 'asc';
    }

    this.filteredData.sort((a, b) => {
      const aVal = a[column];
      const bVal = b[column];

      let comparison = 0;
      if (aVal < bVal) comparison = -1;
      if (aVal > bVal) comparison = 1;

      return this.sortDirection === 'asc' ? comparison : -comparison;
    });

    this.render();
  }

  private changePage(page: number): void {
    this.currentPage = page;
    this.render();
  }

  private getPaginatedData(): any[] {
    if (!this.optionsValue.paginated) {
      return this.filteredData;
    }

    const itemsPerPage = this.optionsValue.itemsPerPage || 10;
    const start = (this.currentPage - 1) * itemsPerPage;
    const end = start + itemsPerPage;

    return this.filteredData.slice(start, end);
  }

  private debounce<T extends (...args: any[]) => any>(
    func: T,
    wait: number
  ): (...args: Parameters<T>) => void {
    let timeout: NodeJS.Timeout;
    
    return (...args: Parameters<T>) => {
      clearTimeout(timeout);
      timeout = setTimeout(() => func.apply(this, args), wait);
    };
  }
}
