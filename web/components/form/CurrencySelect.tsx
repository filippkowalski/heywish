'use client';

import { useState } from 'react';
import { Check, ChevronsUpDown } from 'lucide-react';
import { Button } from '@/components/ui/button';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import { Input } from '@/components/ui/input';
import { cn } from '@/lib/utils';
import { CURRENCIES, getCurrency } from '@/lib/currencies';

interface CurrencySelectProps {
  value: string;
  onValueChange: (value: string) => void;
  disabled?: boolean;
}

export function CurrencySelect({ value, onValueChange, disabled }: CurrencySelectProps) {
  const [open, setOpen] = useState(false);
  const [search, setSearch] = useState('');

  const selectedCurrency = getCurrency(value);

  const filteredCurrencies = CURRENCIES.filter(
    (currency) =>
      currency.code.toLowerCase().includes(search.toLowerCase()) ||
      currency.name.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <DropdownMenu open={open} onOpenChange={setOpen}>
      <DropdownMenuTrigger asChild>
        <Button
          variant="outline"
          role="combobox"
          aria-expanded={open}
          className="w-full justify-between overflow-hidden"
          disabled={disabled}
        >
          {selectedCurrency ? (
            <span className="flex items-center gap-2 overflow-hidden min-w-0 flex-1">
              <span className="text-lg shrink-0">{selectedCurrency.flag}</span>
              <span className="font-medium shrink-0">{selectedCurrency.code}</span>
              <span className="text-muted-foreground truncate">- {selectedCurrency.name}</span>
            </span>
          ) : (
            <span className="text-muted-foreground">Select currency...</span>
          )}
          <ChevronsUpDown className="ml-2 h-4 w-4 shrink-0 opacity-50" />
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent className="w-[400px] p-0" align="start">
        {/* Search Input */}
        <div className="p-2 border-b">
          <Input
            placeholder="Search currencies..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="h-9"
          />
        </div>

        {/* Currency List */}
        <div className="max-h-[300px] overflow-y-auto">
          {filteredCurrencies.length === 0 ? (
            <div className="py-6 text-center text-sm text-muted-foreground">No currency found</div>
          ) : (
            filteredCurrencies.map((currency) => (
              <DropdownMenuItem
                key={currency.code}
                onClick={() => {
                  onValueChange(currency.code);
                  setOpen(false);
                  setSearch('');
                }}
                className="cursor-pointer"
              >
                <div className="flex items-center gap-2 flex-1">
                  <span className="text-lg">{currency.flag}</span>
                  <span className="font-medium min-w-[50px]">{currency.code}</span>
                  <span className="text-muted-foreground">{currency.name}</span>
                  <span className="ml-auto text-muted-foreground">{currency.symbol}</span>
                </div>
                <Check className={cn('ml-2 h-4 w-4', value === currency.code ? 'opacity-100' : 'opacity-0')} />
              </DropdownMenuItem>
            ))
          )}
        </div>
      </DropdownMenuContent>
    </DropdownMenu>
  );
}
